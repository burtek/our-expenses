/// Represents a settlement transaction between groups/individuals.
class SettlementTransaction {
  /// Person IDs who owe money (debtors)
  final List<String> fromIds;

  /// Person IDs who are owed money (creditors)
  final List<String> toIds;

  /// Amount in minor units
  final int amount;

  final String currency;

  const SettlementTransaction({
    required this.fromIds,
    required this.toIds,
    required this.amount,
    required this.currency,
  });
}
