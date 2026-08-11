import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';

class OverviewTab extends ConsumerWidget {
  final String tripId;
  const OverviewTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));
    final participantsAsync = ref.watch(personsProvider(tripId));
    final l10n = AppLocalizations.of(context)!;

    return expensesAsync.when(
      data: (expenses) {
        final participants = participantsAsync.valueOrNull ?? [];
        final actualExpenses = expenses.where(
          (expense) => !expense.isSettlementTransfer,
        );
        final totalSpent = actualExpenses.fold<int>(
          0,
          (sum, e) => sum + e.totalAmount,
        );
        final trip = ref.watch(tripsProvider).valueOrNull?.firstWhere(
              (t) => t.id == tripId,
              orElse: () => Trip(
                id: tripId,
                name: '',
                currency: 'EUR',
                createdAt: DateTime.now(),
              ),
            );
        final currency = trip?.currency ?? 'EUR';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.total}: ${_formatMoney(totalSpent, currency)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('${l10n.expenses}: ${actualExpenses.length}'),
                    Text('${l10n.participants}: ${participants.length}'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _formatMoney(int amount, String currency) {
    final major = amount ~/ 100;
    final minor = amount % 100;
    return '$major.${minor.toString().padLeft(2, '0')} $currency';
  }
}
