import 'package:expense_settler/domain/models/models.dart';
import 'package:expense_settler/domain/services/trip_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = TripExportService();
  const trip = Trip(
    id: 'trip-1',
    name: 'Weekend, "City" Break',
    description: 'Test trip',
    currency: 'EUR',
    createdAt: DateTime(2026, 1, 2),
  );
  const participants = [
    Person(id: 'p1', displayName: 'Alice', tripId: trip.id),
    Person(id: 'p2', displayName: 'Bob', tripId: trip.id),
  ];
  const expenses = [
    Expense(
      id: 'e1',
      tripId: trip.id,
      description: 'Dinner',
      dateTime: DateTime(2026, 2, 1),
      totalAmount: 1234,
      currency: 'EUR',
      splitMode: SplitMode.equal,
      payers: [ExpensePayer(personId: 'p1', amount: 1234)],
      beneficiaries: [
        ExpenseBeneficiary(personId: 'p1', amount: 617),
        ExpenseBeneficiary(personId: 'p2', amount: 617),
      ],
    ),
  ];

  test('creates CSV export with escaped fields and values', () {
    final result = service.toCsv(
      trip: trip,
      participants: participants,
      expenses: expenses,
    );

    expect(result, contains('"trip","date","description","total_amount"'));
    expect(result, contains('"Weekend, ""City"" Break"'));
    expect(result, contains('"Dinner"'));
    expect(result, contains('"12.34"'));
    expect(result, contains('"Alice: 12.34"'));
  });

  test('creates TXT export with sections and readable lines', () {
    final result = service.toTxt(
      trip: trip,
      participants: participants,
      expenses: expenses,
    );

    expect(result, contains('Trip: Weekend, "City" Break'));
    expect(result, contains('Participants:'));
    expect(result, contains('- Alice'));
    expect(result, contains('Expenses:'));
    expect(result, contains('2026-02-01 | Dinner | 12.34 EUR'));
  });
}
