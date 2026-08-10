import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/providers.dart';

class SettlementTab extends ConsumerWidget {
  final String tripId;
  const SettlementTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementResultProvider(tripId));
    final participantsAsync = ref.watch(personsProvider(tripId));
    final l10n = AppLocalizations.of(context)!;

    return settlementAsync.when(
      data: (result) {
        final participants = participantsAsync.valueOrNull ?? [];
        final nameMap = {for (final p in participants) p.id: p.displayName};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Individual balances
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
            // Transactions
            Text(
              l10n.transactions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (result.transactions.isEmpty)
              Center(child: Text(l10n.noTransactions)),
            ...result.transactions.map((tx) {
              final fromNames = tx.fromIds
                  .map((id) => nameMap[id] ?? id)
                  .join(' & ');
              final toNames = tx.toIds
                  .map((id) => nameMap[id] ?? id)
                  .join(' & ');
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '$fromNames → $toNames: ${_formatAmount(tx.amount)} ${tx.currency}',
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
}
