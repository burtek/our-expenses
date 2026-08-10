import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
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
            final amount = expense.totalAmount;
            final major = amount ~/ 100;
            final minor = amount % 100;
            return ListTile(
              title: Text(expense.description),
              subtitle: Text('${l10n.payers}: $payerNames'),
              trailing: Text(
                  '$major.${minor.toString().padLeft(2, '0')} ${expense.currency}'),
              onTap: () => context
                  .go('/trip/$tripId/edit-expense/${expense.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
