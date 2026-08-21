import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart'
    show XTypeGroup, getSaveLocation;
import 'package:share_plus/share_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/services/trip_export_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/expenses_tab.dart';
import '../widgets/participants_tab.dart';
import '../widgets/settlement_tab.dart';
import '../widgets/overview_tab.dart';

enum _ExportAction { saveCsv, shareCsv, saveTxt, shareTxt }

class TripDetailScreen extends ConsumerWidget {
  static final _fileNameSanitizer = RegExp(r'[^a-zA-Z0-9_\-]');

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
            actions: [
              PopupMenuButton<_ExportAction>(
                onSelected: (action) =>
                    _handleExport(context, ref, action, l10n),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _ExportAction.saveCsv,
                    child: Text(l10n.exportSaveCsv),
                  ),
                  PopupMenuItem(
                    value: _ExportAction.shareCsv,
                    child: Text(l10n.exportShareCsv),
                  ),
                  PopupMenuItem(
                    value: _ExportAction.saveTxt,
                    child: Text(l10n.exportSaveTxt),
                  ),
                  PopupMenuItem(
                    value: _ExportAction.shareTxt,
                    child: Text(l10n.exportShareTxt),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.overview),
                Tab(text: l10n.expenses),
                Tab(text: l10n.participants),
                Tab(text: l10n.settlement),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: TabBarView(
              children: [
                OverviewTab(tripId: tripId),
                ExpensesTab(tripId: tripId),
                ParticipantsTab(tripId: tripId),
                SettlementTab(tripId: tripId),
              ],
            ),
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

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    _ExportAction action,
    AppLocalizations l10n,
  ) async {
    final trip = await ref.read(tripRepositoryProvider).getTripById(tripId);
    if (trip == null || !context.mounted) {
      return;
    }

    final participants = await ref
        .read(personRepositoryProvider)
        .getPersonsByTrip(tripId);
    if (!context.mounted) return;
    final expenses = await ref
        .read(expenseRepositoryProvider)
        .getExpensesByTrip(tripId);
    if (!context.mounted) return;

    final exportService = const TripExportService();
    final isCsv =
        action == _ExportAction.saveCsv || action == _ExportAction.shareCsv;
    final extension = isCsv ? 'csv' : 'txt';
    final content = isCsv
        ? exportService.toCsv(
            trip: trip,
            participants: participants,
            expenses: expenses,
          )
        : exportService.toTxt(
            trip: trip,
            participants: participants,
            expenses: expenses,
          );
    final fileName =
        '${trip.name.replaceAll(_fileNameSanitizer, '_')}.$extension';

    try {
      if (action == _ExportAction.saveCsv || action == _ExportAction.saveTxt) {
        final location = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: [
            XTypeGroup(label: extension.toUpperCase(), extensions: [extension]),
          ],
        );
        if (location == null || !context.mounted) {
          return;
        }
        await File(location.path).writeAsString(content, encoding: utf8);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportSaved)));
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);
      await Share.shareXFiles([XFile(file.path)]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.exportShared)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    }
  }
}
