/// Represents a monetary amount using integer minor units (cents/grosze).
class Money {
  final int amount; // in minor units (cents)
  final String currency;

  const Money({required this.amount, required this.currency});

  Money operator +(Money other) {
    assert(currency == other.currency);
    return Money(amount: amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    assert(currency == other.currency);
    return Money(amount: amount - other.amount, currency: currency);
  }

  Money operator -() => Money(amount: -amount, currency: currency);

  bool get isZero => amount == 0;
  bool get isPositive => amount > 0;
  bool get isNegative => amount < 0;

  String get formatted {
    final major = amount.abs() ~/ 100;
    final minor = amount.abs() % 100;
    final sign = amount < 0 ? '-' : '';
    return '$sign$major.${minor.toString().padLeft(2, '0')} $currency';
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => formatted;
}
