import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/models.dart';
import '../../domain/services/settlement_calculator.dart';
import '../providers/providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? expenseId;
  const AddExpenseScreen({super.key, required this.tripId, this.expenseId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  SplitMode _splitMode = SplitMode.equal;
  DateTime _date = DateTime.now();
  final Map<String, int> _payerAmounts = {};
  final Map<String, int> _beneficiaryShares = {};
  final Map<String, int> _beneficiaryAmounts = {};
  Set<String> _selectedPayers = {};
  Set<String> _selectedBeneficiaries = {};
  bool _loaded = false;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(personsProvider(widget.tripId));
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.expenseId != null;

    // Load existing expense if editing
    if (isEdit && !_loaded) {
      final expensesAsync = ref.watch(expensesProvider(widget.tripId));
      expensesAsync.whenData((expenses) {
        final expense =
            expenses.where((e) => e.id == widget.expenseId).firstOrNull;
        if (expense != null && !_loaded) {
          _loaded = true;
          _descController.text = expense.description;
          _amountController.text = (expense.totalAmount / 100).toString();
          _splitMode = expense.splitMode;
          _date = expense.dateTime;
          _selectedPayers = expense.payers.map((p) => p.personId).toSet();
          _selectedBeneficiaries =
              expense.beneficiaries.map((b) => b.personId).toSet();
          for (final p in expense.payers) {
            _payerAmounts[p.personId] = p.amount;
          }
          for (final b in expense.beneficiaries) {
            _beneficiaryAmounts[b.personId] = b.amount;
            if (b.shares != null) {
              _beneficiaryShares[b.personId] = b.shares!;
            }
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editExpense : l10n.addExpense),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref
                    .read(expensesProvider(widget.tripId).notifier)
                    .deleteExpense(widget.expenseId!);
                _closeScreen();
              },
            ),
        ],
      ),
      body: participantsAsync.when(
        data: (participants) => _buildForm(context, participants, l10n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Person> participants,
    AppLocalizations l10n,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _descController,
          decoration: InputDecoration(labelText: l10n.expenseDescription),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(labelText: l10n.amount),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
        ),
        const SizedBox(height: 16),
        // Split mode
        SegmentedButton<SplitMode>(
          segments: [
            ButtonSegment(
              value: SplitMode.equal,
              label: Text(l10n.splitEqually),
            ),
            ButtonSegment(
              value: SplitMode.byShares,
              label: Text(l10n.splitByShares),
            ),
            ButtonSegment(
              value: SplitMode.exactAmounts,
              label: Text(l10n.splitExactAmounts),
            ),
          ],
          selected: {_splitMode},
          onSelectionChanged: (v) => setState(() => _splitMode = v.first),
        ),
        const SizedBox(height: 16),
        // Payers
        Text(l10n.payers, style: Theme.of(context).textTheme.titleSmall),
        ...participants.map((p) {
          final selected = _selectedPayers.contains(p.id);
          return CheckboxListTile(
            title: Text(p.displayName),
            value: selected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedPayers.add(p.id);
                } else {
                  _selectedPayers.remove(p.id);
                  _payerAmounts.remove(p.id);
                }
              });
            },
          );
        }),
        const SizedBox(height: 16),
        // Beneficiaries
        Text(l10n.beneficiaries, style: Theme.of(context).textTheme.titleSmall),
        ...participants.map((p) {
          final selected = _selectedBeneficiaries.contains(p.id);
          return CheckboxListTile(
            title: Text(p.displayName),
            value: selected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedBeneficiaries.add(p.id);
                } else {
                  _selectedBeneficiaries.remove(p.id);
                }
              });
            },
          );
        }),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _save(participants),
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _save(List<Person> participants) {
    final desc = _descController.text.trim();
    if (desc.isEmpty) return;

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final totalAmount = (double.parse(amountText) * 100).round();
    if (totalAmount <= 0) return;
    if (_selectedPayers.isEmpty || _selectedBeneficiaries.isEmpty) return;

    final trip = ref
        .read(tripsProvider)
        .valueOrNull
        ?.firstWhere((t) => t.id == widget.tripId);
    final currency = trip?.currency ?? 'EUR';

    // Build payers - split equally among selected payers
    final payerList = _selectedPayers.toList();
    final payerSplits = SettlementCalculator.splitEqually(
      totalAmount,
      payerList.length,
    );
    final payers = List.generate(
      payerList.length,
      (i) => ExpensePayer(personId: payerList[i], amount: payerSplits[i]),
    );

    // Build beneficiaries based on split mode
    final benList = _selectedBeneficiaries.toList();
    List<ExpenseBeneficiary> beneficiaries;
    switch (_splitMode) {
      case SplitMode.equal:
        final splits = SettlementCalculator.splitEqually(
          totalAmount,
          benList.length,
        );
        beneficiaries = List.generate(
          benList.length,
          (i) => ExpenseBeneficiary(personId: benList[i], amount: splits[i]),
        );
        break;
      case SplitMode.byShares:
        final shares =
            benList.map((id) => _beneficiaryShares[id] ?? 1).toList();
        final splits = SettlementCalculator.splitByShares(totalAmount, shares);
        beneficiaries = List.generate(
          benList.length,
          (i) => ExpenseBeneficiary(
            personId: benList[i],
            amount: splits[i],
            shares: shares[i],
          ),
        );
        break;
      case SplitMode.exactAmounts:
        beneficiaries = benList
            .map(
              (id) => ExpenseBeneficiary(
                personId: id,
                amount: _beneficiaryAmounts[id] ?? 0,
              ),
            )
            .toList();
        break;
    }

    final expense = Expense(
      id: widget.expenseId ?? const Uuid().v4(),
      tripId: widget.tripId,
      description: desc,
      dateTime: _date,
      totalAmount: totalAmount,
      currency: currency,
      splitMode: _splitMode,
      payers: payers,
      beneficiaries: beneficiaries,
    );

    if (widget.expenseId != null) {
      ref.read(expensesProvider(widget.tripId).notifier).updateExpense(expense);
    } else {
      ref.read(expensesProvider(widget.tripId).notifier).addExpense(expense);
    }
    _closeScreen();
  }

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/trip/${widget.tripId}');
  }
}
