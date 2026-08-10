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
    final multiplePayersSelected = _selectedPayers.length > 1;
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
          return Column(
            children: [
              CheckboxListTile(
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
              ),
              if (selected && multiplePayersSelected)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: TextFormField(
                    key: ValueKey('payer-${p.id}'),
                    initialValue: _formatMinorUnits(_payerAmounts[p.id]),
                    decoration: InputDecoration(labelText: l10n.amount),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onChanged: (value) {
                      final amount = _parseAmountToMinorUnits(value);
                      if (amount == null) {
                        _payerAmounts.remove(p.id);
                      } else {
                        _payerAmounts[p.id] = amount;
                      }
                    },
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 16),
        // Beneficiaries
        Text(l10n.beneficiaries, style: Theme.of(context).textTheme.titleSmall),
        ...participants.map((p) {
          final selected = _selectedBeneficiaries.contains(p.id);
          return Column(
            children: [
              CheckboxListTile(
                title: Text(p.displayName),
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedBeneficiaries.add(p.id);
                      if (_splitMode == SplitMode.byShares) {
                        _beneficiaryShares.putIfAbsent(p.id, () => 1);
                      }
                    } else {
                      _selectedBeneficiaries.remove(p.id);
                      _beneficiaryShares.remove(p.id);
                      _beneficiaryAmounts.remove(p.id);
                    }
                  });
                },
              ),
              if (selected && _splitMode == SplitMode.byShares)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: TextFormField(
                    key: ValueKey('shares-${p.id}'),
                    initialValue: (_beneficiaryShares[p.id] ?? 1).toString(),
                    decoration: InputDecoration(labelText: l10n.shares),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      final shares = int.tryParse(value);
                      if (shares == null) {
                        _beneficiaryShares.remove(p.id);
                      } else {
                        _beneficiaryShares[p.id] = shares;
                      }
                    },
                  ),
                ),
              if (selected && _splitMode == SplitMode.exactAmounts)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: TextFormField(
                    key: ValueKey('beneficiary-${p.id}'),
                    initialValue: _formatMinorUnits(_beneficiaryAmounts[p.id]),
                    decoration: InputDecoration(labelText: l10n.amount),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onChanged: (value) {
                      final amount = _parseAmountToMinorUnits(value);
                      if (amount == null) {
                        _beneficiaryAmounts.remove(p.id);
                      } else {
                        _beneficiaryAmounts[p.id] = amount;
                      }
                    },
                  ),
                ),
            ],
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
    final l10n = AppLocalizations.of(context)!;
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      _showError(l10n.expenseDescriptionRequired);
      return;
    }

    final amountText = _amountController.text.trim();
    final totalAmount = _parseAmountToMinorUnits(amountText);
    if (totalAmount == null || totalAmount <= 0) {
      _showError(l10n.invalidAmount);
      return;
    }
    if (_selectedPayers.isEmpty) {
      _showError(l10n.selectAtLeastOnePayer);
      return;
    }
    if (_selectedBeneficiaries.isEmpty) {
      _showError(l10n.selectAtLeastOneBeneficiary);
      return;
    }

    final trip = ref
        .read(tripsProvider)
        .valueOrNull
        ?.firstWhere((t) => t.id == widget.tripId);
    final currency = trip?.currency ?? 'EUR';

    final payerList = _selectedPayers.toList();
    late final List<ExpensePayer> payers;
    if (payerList.length == 1) {
      payers = [ExpensePayer(personId: payerList.first, amount: totalAmount)];
    } else {
      final payerAmounts = payerList
          .map((id) => _payerAmounts[id])
          .whereType<int>()
          .toList();
      final payerSum = payerAmounts.fold<int>(
        0,
        (sum, amount) => sum + amount,
      );
      final hasInvalidPayerTotal =
          payerAmounts.length != payerList.length || payerSum != totalAmount;
      if (hasInvalidPayerTotal) {
        _showError(l10n.payerAmountsMustMatchTotal);
        return;
      }
      payers = payerList
          .map((id) => ExpensePayer(personId: id, amount: _payerAmounts[id]!))
          .toList();
    }

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
        if (shares.any((share) => share <= 0)) {
          _showError(l10n.sharesMustBePositive);
          return;
        }
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
        final amounts = benList
            .map((id) => _beneficiaryAmounts[id])
            .whereType<int>()
            .toList();
        final beneficiarySum =
            amounts.fold<int>(0, (sum, amount) => sum + amount);
        final hasInvalidBeneficiaryTotal =
            amounts.length != benList.length || beneficiarySum != totalAmount;
        if (hasInvalidBeneficiaryTotal) {
          _showError(l10n.beneficiaryAmountsMustMatchTotal);
          return;
        }
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
      ref
          .read(expensesProvider(widget.tripId).notifier)
          .updateExpense(expense);
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

  int? _parseAmountToMinorUnits(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    final parsed = double.tryParse(normalized);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  String _formatMinorUnits(int? amount) {
    if (amount == null) return '';
    final major = amount ~/ 100;
    final minor = amount % 100;
    return '$major.${minor.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
