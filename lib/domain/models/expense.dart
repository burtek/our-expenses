enum SplitMode { equal, byShares, exactAmounts }

class ExpensePayer {
  final String personId;
  final int amount; // minor units

  const ExpensePayer({required this.personId, required this.amount});
}

class ExpenseBeneficiary {
  final String personId;
  final int amount; // minor units (resolved amount)
  final int? shares; // only for byShares mode

  const ExpenseBeneficiary({
    required this.personId,
    required this.amount,
    this.shares,
  });
}

class Expense {
  final String id;
  final String tripId;
  final String description;
  final DateTime dateTime;
  final int totalAmount; // minor units
  final String currency;
  final SplitMode splitMode;
  final List<ExpensePayer> payers;
  final List<ExpenseBeneficiary> beneficiaries;

  const Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.dateTime,
    required this.totalAmount,
    required this.currency,
    required this.splitMode,
    required this.payers,
    required this.beneficiaries,
  });

  @override
  bool operator ==(Object other) => other is Expense && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
