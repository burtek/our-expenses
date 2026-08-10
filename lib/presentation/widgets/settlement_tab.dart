import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/models.dart';
import '../providers/providers.dart';

class SettlementTab extends ConsumerWidget {
  final String tripId;
  const SettlementTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementResultProvider(tripId));
    final participantsAsync = ref.watch(personsProvider(tripId));
    final groupsAsync = ref.watch(settlementGroupsProvider(tripId));
    final tripsAsync = ref.watch(tripsProvider);
    final l10n = AppLocalizations.of(context)!;

    return settlementAsync.when(
      data: (result) {
        final participants = participantsAsync.valueOrNull ?? [];
        final groups = groupsAsync.valueOrNull ?? [];
        final trip = tripsAsync.valueOrNull?.firstWhere(
          (item) => item.id == tripId,
          orElse: () => Trip(
            id: tripId,
            name: '',
            currency: 'EUR',
            createdAt: DateTime.now(),
          ),
        );
        final currency = trip?.currency ?? 'EUR';
        final nameMap = {for (final participant in participants) participant.id: participant.displayName};
        final groupNameMap = {for (final group in groups) group.id: group.name};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.balances, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...result.individualBalances.entries.map((entry) {
              final name = nameMap[entry.key] ?? entry.key;
              final amount = entry.value;
              final color = amount >= 0 ? Colors.green : Colors.red;
              final label = amount >= 0 ? l10n.isOwed : l10n.owes;
              return ListTile(
                dense: true,
                title: Text(name),
                trailing: Text(
                  '${_formatAmount(amount.abs())} ($label)',
                  style: TextStyle(color: color),
                ),
              );
            }),
            const Divider(height: 32),
            Text(
              l10n.settlementGroups,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...result.groupBalances.entries.map((entry) {
              final amount = entry.value;
              final memberNames = (result.groupMembers[entry.key] ?? const <String>[])
                  .map((id) => nameMap[id] ?? id)
                  .join(', ');
              final label = groupNameMap[entry.key] ?? memberNames;
              final color = amount >= 0 ? Colors.green : Colors.red;
              return ListTile(
                dense: true,
                title: Text(label),
                subtitle: memberNames == label ? null : Text(memberNames),
                trailing: Text(
                  _formatAmount(amount.abs()),
                  style: TextStyle(color: color),
                ),
              );
            }),
            const Divider(height: 32),
            Text(
              l10n.transactions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (result.transactions.isEmpty)
              Center(child: Text(l10n.noTransactions))
            else
              ...result.transactions.map((transaction) {
                final fromNames =
                    transaction.fromIds.map((id) => nameMap[id] ?? id).join(' & ');
                final toNames =
                    transaction.toIds.map((id) => nameMap[id] ?? id).join(' & ');
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$fromNames → $toNames: ${_formatAmount(transaction.amount)} ${transaction.currency}',
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _markAsSettled(
                              context,
                              ref,
                              l10n,
                              transaction,
                              currency,
                              nameMap,
                            ),
                            child: Text(l10n.markAsSettled),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _formatAmount(int amount) {
    final major = amount ~/ 100;
    final minor = amount % 100;
    return '$major.${minor.toString().padLeft(2, '0')}';
  }

  void _markAsSettled(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SettlementTransaction transaction,
    String currency,
    Map<String, String> nameMap,
  ) {
    String fromId = transaction.fromIds.first;
    String toId = transaction.toIds.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.markAsSettled),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: fromId,
                decoration: InputDecoration(labelText: l10n.payers),
                items: transaction.fromIds
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(nameMap[id] ?? id),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => fromId = value ?? fromId),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: toId,
                decoration: InputDecoration(labelText: l10n.beneficiaries),
                items: transaction.toIds
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(nameMap[id] ?? id),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => toId = value ?? toId),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final payerName = nameMap[fromId] ?? fromId;
                final beneficiaryName = nameMap[toId] ?? toId;
                final expense = Expense(
                  id: const Uuid().v4(),
                  tripId: tripId,
                  description:
                      '$settlementTransferDescriptionPrefix$payerName → $beneficiaryName',
                  dateTime: DateTime.now(),
                  totalAmount: transaction.amount,
                  currency: currency,
                  splitMode: SplitMode.exactAmounts,
                  payers: [
                    ExpensePayer(personId: fromId, amount: transaction.amount),
                  ],
                  beneficiaries: [
                    ExpenseBeneficiary(personId: toId, amount: transaction.amount),
                  ],
                );
                ref.read(expensesProvider(tripId).notifier).addExpense(expense);
                Navigator.pop(ctx);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
