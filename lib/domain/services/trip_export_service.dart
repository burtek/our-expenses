import '../models/models.dart';

class TripExportService {
  const TripExportService();

  String toCsv({
    required Trip trip,
    required List<Person> participants,
    required List<Expense> expenses,
  }) {
    final namesById = {for (final person in participants) person.id: person.displayName};
    final rows = <List<String>>[
      [
        'trip',
        'date',
        'description',
        'total_amount',
        'currency',
        'split_mode',
        'payers',
        'beneficiaries',
      ],
      ...expenses.map(
        (expense) => [
          trip.name,
          _formatDate(expense.dateTime),
          expense.displayDescription,
          _formatAmount(expense.totalAmount),
          expense.currency,
          expense.splitMode.name,
          expense.payers
              .map((payer) => '${namesById[payer.personId] ?? payer.personId}: ${_formatAmount(payer.amount)}')
              .join(' | '),
          expense.beneficiaries
              .map(
                (beneficiary) =>
                    '${namesById[beneficiary.personId] ?? beneficiary.personId}: ${_formatAmount(beneficiary.amount)}',
              )
              .join(' | '),
        ],
      ),
    ];

    return rows.map((row) => row.map(_escapeCsvField).join(',')).join('\r\n');
  }

  String toTxt({
    required Trip trip,
    required List<Person> participants,
    required List<Expense> expenses,
  }) {
    final namesById = {for (final person in participants) person.id: person.displayName};
    final buffer = StringBuffer()
      ..writeln('Trip: ${trip.name}')
      ..writeln('Currency: ${trip.currency}');

    if ((trip.description ?? '').isNotEmpty) {
      buffer.writeln('Description: ${trip.description}');
    }

    buffer
      ..writeln()
      ..writeln('Participants:');
    for (final participant in participants) {
      buffer.writeln('- ${participant.displayName}');
    }

    buffer
      ..writeln()
      ..writeln('Expenses:');
    for (final expense in expenses) {
      buffer
        ..writeln(
          '- ${_formatDate(expense.dateTime)} | ${expense.displayDescription} | ${_formatAmount(expense.totalAmount)} ${expense.currency}',
        )
        ..writeln(
          '  Payers: ${expense.payers.map((payer) => '${namesById[payer.personId] ?? payer.personId} (${_formatAmount(payer.amount)})').join(', ')}',
        )
        ..writeln(
          '  Beneficiaries: ${expense.beneficiaries.map((beneficiary) => '${namesById[beneficiary.personId] ?? beneficiary.personId} (${_formatAmount(beneficiary.amount)})').join(', ')}',
        );
    }

    return buffer.toString().trimRight();
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _formatAmount(int amountInMinorUnits) {
    final major = amountInMinorUnits.abs() ~/ 100;
    final minor = amountInMinorUnits.abs() % 100;
    final sign = amountInMinorUnits < 0 ? '-' : '';
    return '$sign$major.${minor.toString().padLeft(2, '0')}';
  }

  String _escapeCsvField(String value) {
    final escapedValue = value.replaceAll('"', '""');
    return '"$escapedValue"';
  }
}
