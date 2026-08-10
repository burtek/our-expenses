import '../models/models.dart';

/// Result of settlement calculation
class SettlementResult {
  /// Net balance per person (positive = owed money, negative = owes money)
  final Map<String, int> individualBalances;

  /// Net balance per settlement group/individual entity
  final Map<String, int> groupBalances;

  /// Group label mapping (group id -> member ids)
  final Map<String, List<String>> groupMembers;

  /// Minimized settlement transactions
  final List<SettlementTransaction> transactions;

  const SettlementResult({
    required this.individualBalances,
    required this.groupBalances,
    required this.groupMembers,
    required this.transactions,
  });
}

class SettlementCalculator {
  const SettlementCalculator();

  /// Split an expense total equally among beneficiaries.
  /// Returns list of amounts in minor units, distributing remainder to first N.
  static List<int> splitEqually(int total, int count) {
    if (count == 0) return [];
    final base = total ~/ count;
    final remainder = total - base * count;
    return List.generate(
      count,
      (i) => i < remainder ? base + 1 : base,
    );
  }

  /// Split by shares. Distribute proportionally, remainder to first beneficiary.
  static List<int> splitByShares(int total, List<int> shares) {
    if (shares.isEmpty) return [];
    final totalShares = shares.fold<int>(0, (a, b) => a + b);
    if (totalShares == 0) return List.filled(shares.length, 0);

    final amounts = <int>[];
    int distributed = 0;
    for (int i = 0; i < shares.length; i++) {
      if (i == shares.length - 1) {
        // Last person gets remainder to ensure sum == total
        amounts.add(total - distributed);
      } else {
        final amount = (total * shares[i]) ~/ totalShares;
        amounts.add(amount);
        distributed += amount;
      }
    }
    return amounts;
  }

  /// Calculate settlement for a trip given expenses, participants, and groups.
  SettlementResult calculate({
    required List<Expense> expenses,
    required List<Person> participants,
    required List<SettlementGroup> groups,
    required String currency,
  }) {
    // Step 1: Calculate net balance per participant
    final balances = <String, int>{};
    for (final p in participants) {
      balances[p.id] = 0;
    }

    for (final expense in expenses) {
      for (final payer in expense.payers) {
        balances[payer.personId] =
            (balances[payer.personId] ?? 0) + payer.amount;
      }
      for (final ben in expense.beneficiaries) {
        balances[ben.personId] =
            (balances[ben.personId] ?? 0) - ben.amount;
      }
    }

    // Step 2: Aggregate by settlement groups
    // Build person -> group mapping
    final personToGroup = <String, String>{};
    for (final group in groups) {
      for (final memberId in group.memberIds) {
        personToGroup[memberId] = group.id;
      }
    }

    // Group balances: group id (or person id for ungrouped) -> balance
    final groupBalances = <String, int>{};
    final groupMembers = <String, List<String>>{};

    for (final entry in balances.entries) {
      final personId = entry.key;
      final balance = entry.value;
      final groupId = personToGroup[personId] ?? personId;

      groupBalances[groupId] = (groupBalances[groupId] ?? 0) + balance;
      groupMembers.putIfAbsent(groupId, () => []).add(personId);
    }

    // Step 3: Minimize transactions using greedy algorithm
    final transactions = _minimizeTransactions(
      groupBalances: groupBalances,
      groupMembers: groupMembers,
      currency: currency,
    );

    return SettlementResult(
      individualBalances: balances,
      groupBalances: groupBalances,
      groupMembers: groupMembers,
      transactions: transactions,
    );
  }

  List<SettlementTransaction> _minimizeTransactions({
    required Map<String, int> groupBalances,
    required Map<String, List<String>> groupMembers,
    required String currency,
  }) {
    // Separate creditors and debtors
    final creditors = <MapEntry<String, int>>[];
    final debtors = <MapEntry<String, int>>[];

    for (final entry in groupBalances.entries) {
      if (entry.value > 0) {
        creditors.add(entry);
      } else if (entry.value < 0) {
        debtors.add(entry);
      }
    }

    // Sort by absolute value descending
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => a.value.compareTo(b.value)); // most negative first

    // Greedy matching
    final transactions = <SettlementTransaction>[];
    final creditAmounts = {for (final c in creditors) c.key: c.value};
    final debtAmounts = {for (final d in debtors) d.key: -d.value}; // positive

    while (creditAmounts.isNotEmpty && debtAmounts.isNotEmpty) {
      // Find largest creditor and largest debtor
      String? maxCreditor;
      int maxCreditAmt = 0;
      for (final entry in creditAmounts.entries) {
        if (entry.value > maxCreditAmt) {
          maxCreditAmt = entry.value;
          maxCreditor = entry.key;
        }
      }

      String? maxDebtor;
      int maxDebtAmt = 0;
      for (final entry in debtAmounts.entries) {
        if (entry.value > maxDebtAmt) {
          maxDebtAmt = entry.value;
          maxDebtor = entry.key;
        }
      }

      if (maxCreditor == null || maxDebtor == null) break;

      final settleAmount =
          maxCreditAmt < maxDebtAmt ? maxCreditAmt : maxDebtAmt;

      transactions.add(SettlementTransaction(
        fromIds: groupMembers[maxDebtor] ?? [maxDebtor],
        toIds: groupMembers[maxCreditor] ?? [maxCreditor],
        amount: settleAmount,
        currency: currency,
      ));

      creditAmounts[maxCreditor] = maxCreditAmt - settleAmount;
      debtAmounts[maxDebtor] = maxDebtAmt - settleAmount;

      if (creditAmounts[maxCreditor] == 0) creditAmounts.remove(maxCreditor);
      if (debtAmounts[maxDebtor] == 0) debtAmounts.remove(maxDebtor);
    }

    return transactions;
  }
}
