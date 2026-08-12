import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';

class ExpensesTab extends ConsumerWidget {
  final String tripId;
  const ExpensesTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));
    final participantsAsync = ref.watch(personsProvider(tripId));
    final l10n = AppLocalizations.of(context)!;

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(child: Text(l10n.noExpenses));
        }
        final participants = participantsAsync.valueOrNull ?? [];
        final nameMap = {for (final p in participants) p.id: p.displayName};

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final payerNames = expense.payers
                .map((p) => nameMap[p.personId] ?? '?')
                .join(', ');
            final beneficiaryNames = expense.beneficiaries
                .map((b) => nameMap[b.personId] ?? '?')
                .join(', ');
            final amount = expense.totalAmount;
            final major = amount ~/ 100;
            final minor = amount % 100;
            final dateStr =
                '${expense.dateTime.year.toString().padLeft(4, '0')}-'
                '${expense.dateTime.month.toString().padLeft(2, '0')}-'
                '${expense.dateTime.day.toString().padLeft(2, '0')}';
            return ListTile(
              leading: expense.isSettlementTransfer
                  ? const Icon(Icons.swap_horiz)
                  : null,
              title: Text(
                expense.isSettlementTransfer
                    ? l10n.settleUpTransfer
                    : expense.displayDescription,
              ),
              subtitle: Text(
                expense.isSettlementTransfer
                    ? '$dateStr · $payerNames → $beneficiaryNames'
                    : '$dateStr · ${l10n.payers}: $payerNames',
              ),
              trailing: Text(
                '$major.${minor.toString().padLeft(2, '0')} '
                '${expense.currency}',
              ),
              onTap: expense.isSettlementTransfer
                  ? null
                  : () => context.push(
                        '/trip/$tripId/edit-expense/${expense.id}',
                      ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
