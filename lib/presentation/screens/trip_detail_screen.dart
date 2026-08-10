import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../widgets/expenses_tab.dart';
import '../widgets/participants_tab.dart';
import '../widgets/settlement_tab.dart';
import '../widgets/overview_tab.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    final l10n = AppLocalizations.of(context)!;
    final canPop = context.canPop();

    final trip = tripsAsync.whenOrNull(
      data: (trips) => trips.where((t) => t.id == tripId).firstOrNull,
    );

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => _goBack(context)),
            title: Text(trip?.name ?? ''),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.overview),
                Tab(text: l10n.expenses),
                Tab(text: l10n.participants),
                Tab(text: l10n.settlement),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              OverviewTab(tripId: tripId),
              ExpensesTab(tripId: tripId),
              ParticipantsTab(tripId: tripId),
              SettlementTab(tripId: tripId),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/trip/$tripId/add-expense'),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/');
  }
}
