import 'package:flutter_test/flutter_test.dart';
import 'package:expense_settler/domain/models/models.dart';
import 'package:expense_settler/domain/services/settlement_calculator.dart';

void main() {
  const calculator = SettlementCalculator();

  Person person(String id) => Person(id: id, displayName: id, tripId: 'trip1');

  group('splitEqually', () {
    test('divides evenly', () {
      expect(SettlementCalculator.splitEqually(1000, 4), [250, 250, 250, 250]);
    });

    test('distributes remainder to first N', () {
      // 1000 / 3 = 333 remainder 1
      final result = SettlementCalculator.splitEqually(1000, 3);
      expect(result, [334, 333, 333]);
      expect(result.reduce((a, b) => a + b), 1000);
    });

    test('remainder of 2', () {
      // 100 / 3 = 33 remainder 1
      final result = SettlementCalculator.splitEqually(100, 3);
      expect(result, [34, 33, 33]);
      expect(result.reduce((a, b) => a + b), 100);
    });

    test('single person', () {
      expect(SettlementCalculator.splitEqually(1000, 1), [1000]);
    });

    test('zero count', () {
      expect(SettlementCalculator.splitEqually(1000, 0), []);
    });

    test('one cent', () {
      expect(SettlementCalculator.splitEqually(1, 3), [1, 0, 0]);
    });
  });

  group('splitByShares', () {
    test('equal shares', () {
      final result = SettlementCalculator.splitByShares(1000, [1, 1, 1]);
      expect(result.reduce((a, b) => a + b), 1000);
    });

    test('different shares', () {
      // 1000 split 2:1 = 666, 334
      final result = SettlementCalculator.splitByShares(1000, [2, 1]);
      expect(result[0], 666);
      expect(result[1], 334); // remainder goes to last
      expect(result.reduce((a, b) => a + b), 1000);
    });

    test('3:2:1 shares', () {
      final result = SettlementCalculator.splitByShares(600, [3, 2, 1]);
      expect(result, [300, 200, 100]);
    });

    test('zero total shares', () {
      final result = SettlementCalculator.splitByShares(1000, [0, 0]);
      expect(result, [0, 0]);
    });

    test('single share', () {
      expect(SettlementCalculator.splitByShares(500, [1]), [500]);
    });
  });

  group('Settlement calculation', () {
    test('one payer, one beneficiary', () {
      final persons = [person('A'), person('B')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Lunch',
          dateTime: DateTime.now(),
          totalAmount: 1000,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 1000)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 500),
            const ExpenseBeneficiary(personId: 'B', amount: 500),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      expect(result.individualBalances['A'], 500); // paid 1000, consumed 500
      expect(result.individualBalances['B'], -500); // paid 0, consumed 500
      // Invariant: sum of all balances = 0
      expect(result.individualBalances.values.reduce((a, b) => a + b), 0);
      // One transaction: B -> A for 500
      expect(result.transactions.length, 1);
      expect(result.transactions[0].amount, 500);
    });

    test('one payer, multiple beneficiaries', () {
      final persons = [person('A'), person('B'), person('C')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Dinner',
          dateTime: DateTime.now(),
          totalAmount: 900,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 900)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 300),
            const ExpenseBeneficiary(personId: 'B', amount: 300),
            const ExpenseBeneficiary(personId: 'C', amount: 300),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      expect(result.individualBalances['A'], 600);
      expect(result.individualBalances['B'], -300);
      expect(result.individualBalances['C'], -300);
      expect(result.individualBalances.values.reduce((a, b) => a + b), 0);
    });

    test('multiple payers, one beneficiary', () {
      final persons = [person('A'), person('B'), person('C')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Gift',
          dateTime: DateTime.now(),
          totalAmount: 600,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [
            const ExpensePayer(personId: 'A', amount: 300),
            const ExpensePayer(personId: 'B', amount: 300),
          ],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'C', amount: 600),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      expect(result.individualBalances['A'], 300);
      expect(result.individualBalances['B'], 300);
      expect(result.individualBalances['C'], -600);
      expect(result.individualBalances.values.reduce((a, b) => a + b), 0);
    });

    test('multiple payers, multiple beneficiaries', () {
      final persons = [person('A'), person('B'), person('C'), person('D')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Hotel',
          dateTime: DateTime.now(),
          totalAmount: 4000,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [
            const ExpensePayer(personId: 'A', amount: 3000),
            const ExpensePayer(personId: 'B', amount: 1000),
          ],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 1000),
            const ExpenseBeneficiary(personId: 'B', amount: 1000),
            const ExpenseBeneficiary(personId: 'C', amount: 1000),
            const ExpenseBeneficiary(personId: 'D', amount: 1000),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      expect(result.individualBalances['A'], 2000); // 3000-1000
      expect(result.individualBalances['B'], 0); // 1000-1000
      expect(result.individualBalances['C'], -1000); // 0-1000
      expect(result.individualBalances['D'], -1000); // 0-1000
      expect(result.individualBalances.values.reduce((a, b) => a + b), 0);
    });

    test('equal split with rounding', () {
      final persons = [person('A'), person('B'), person('C')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Coffee',
          dateTime: DateTime.now(),
          totalAmount: 1000,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 1000)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 334),
            const ExpenseBeneficiary(personId: 'B', amount: 333),
            const ExpenseBeneficiary(personId: 'C', amount: 333),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      // Sum of beneficiary amounts = total
      expect(1000, expenses[0].beneficiaries.fold<int>(0, (s, b) => s + b.amount));
      expect(result.individualBalances.values.reduce((a, b) => a + b), 0);
    });

    test('share-based split', () {
      final persons = [person('A'), person('B')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Taxi',
          dateTime: DateTime.now(),
          totalAmount: 1000,
          currency: 'EUR',
          splitMode: SplitMode.byShares,
          payers: [const ExpensePayer(personId: 'A', amount: 1000)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 333, shares: 1),
            const ExpenseBeneficiary(personId: 'B', amount: 667, shares: 2),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      expect(result.individualBalances['A'], 667); // paid 1000, consumed 333
      expect(result.individualBalances['B'], -667); // paid 0, consumed 667
      expect(result.individualBalances.values.reduce((a, b) => a + b), 0);
    });

    test('exact amount split', () {
      final persons = [person('A'), person('B'), person('C')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Mixed',
          dateTime: DateTime.now(),
          totalAmount: 1000,
          currency: 'EUR',
          splitMode: SplitMode.exactAmounts,
          payers: [const ExpensePayer(personId: 'A', amount: 1000)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 200),
            const ExpenseBeneficiary(personId: 'B', amount: 300),
            const ExpenseBeneficiary(personId: 'C', amount: 500),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      expect(result.individualBalances['A'], 800);
      expect(result.individualBalances['B'], -300);
      expect(result.individualBalances['C'], -500);
      expect(result.individualBalances.values.reduce((a, b) => a + b), 0);
    });

    test('zero balances - no transactions needed', () {
      final persons = [person('A'), person('B')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Lunch',
          dateTime: DateTime.now(),
          totalAmount: 500,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 500)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 250),
            const ExpenseBeneficiary(personId: 'B', amount: 250),
          ],
        ),
        Expense(
          id: 'e2',
          tripId: 'trip1',
          description: 'Dinner',
          dateTime: DateTime.now(),
          totalAmount: 500,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'B', amount: 500)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 250),
            const ExpenseBeneficiary(personId: 'B', amount: 250),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      expect(result.individualBalances['A'], 0);
      expect(result.individualBalances['B'], 0);
      expect(result.transactions, isEmpty);
    });

    test('settlement groups aggregate members', () {
      final persons = [person('A'), person('B'), person('C'), person('D')];
      final groups = [
        const SettlementGroup(
            id: 'g1', name: 'Couple1', tripId: 'trip1', memberIds: ['A', 'B']),
        const SettlementGroup(
            id: 'g2', name: 'Couple2', tripId: 'trip1', memberIds: ['C', 'D']),
      ];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Hotel',
          dateTime: DateTime.now(),
          totalAmount: 2000,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 2000)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 500),
            const ExpenseBeneficiary(personId: 'B', amount: 500),
            const ExpenseBeneficiary(personId: 'C', amount: 500),
            const ExpenseBeneficiary(personId: 'D', amount: 500),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: groups,
        currency: 'EUR',
      );

      // Group g1 (A+B): A has +1500, B has -500 => net +1000
      // Group g2 (C+D): C has -500, D has -500 => net -1000
      expect(result.groupBalances['g1'], 1000);
      expect(result.groupBalances['g2'], -1000);
      expect(result.groupBalances.values.reduce((a, b) => a + b), 0);

      // One transaction: g2 -> g1
      expect(result.transactions.length, 1);
      expect(result.transactions[0].amount, 1000);
    });

    test('mixed grouped and ungrouped participants', () {
      final persons = [person('A'), person('B'), person('C')];
      final groups = [
        const SettlementGroup(
            id: 'g1', name: 'Couple', tripId: 'trip1', memberIds: ['A', 'B']),
      ];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Dinner',
          dateTime: DateTime.now(),
          totalAmount: 900,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'C', amount: 900)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 300),
            const ExpenseBeneficiary(personId: 'B', amount: 300),
            const ExpenseBeneficiary(personId: 'C', amount: 300),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: groups,
        currency: 'EUR',
      );

      // A: 0-300=-300, B: 0-300=-300
      // Group g1: -600
      // C: 900-300=600 (ungrouped, so entity = 'C')
      expect(result.groupBalances['g1'], -600);
      expect(result.groupBalances['C'], 600);
      expect(result.groupBalances.values.reduce((a, b) => a + b), 0);
    });

    test('several expenses accumulate', () {
      final persons = [person('A'), person('B'), person('C')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Expense 1',
          dateTime: DateTime.now(),
          totalAmount: 300,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 300)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 100),
            const ExpenseBeneficiary(personId: 'B', amount: 100),
            const ExpenseBeneficiary(personId: 'C', amount: 100),
          ],
        ),
        Expense(
          id: 'e2',
          tripId: 'trip1',
          description: 'Expense 2',
          dateTime: DateTime.now(),
          totalAmount: 600,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'B', amount: 600)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 200),
            const ExpenseBeneficiary(personId: 'B', amount: 200),
            const ExpenseBeneficiary(personId: 'C', amount: 200),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      // A: paid 300, consumed 300 => 0
      // B: paid 600, consumed 300 => +300
      // C: paid 0, consumed 300 => -300
      expect(result.individualBalances['A'], 0);
      expect(result.individualBalances['B'], 300);
      expect(result.individualBalances['C'], -300);
      expect(result.individualBalances.values.reduce((a, b) => a + b), 0);
    });

    test('settlement minimization reduces transactions', () {
      // A owes 100, B owes 200, C is owed 300
      final persons = [person('A'), person('B'), person('C')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Big expense',
          dateTime: DateTime.now(),
          totalAmount: 300,
          currency: 'EUR',
          splitMode: SplitMode.exactAmounts,
          payers: [const ExpensePayer(personId: 'C', amount: 300)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 100),
            const ExpenseBeneficiary(personId: 'B', amount: 200),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      // Should have 2 transactions max (B->C for 200, A->C for 100)
      expect(result.transactions.length, 2);
      final totalSettled =
          result.transactions.fold<int>(0, (s, t) => s + t.amount);
      expect(totalSettled, 300);
    });

    test('balances cancel exactly with multiple expenses', () {
      final persons = [person('A'), person('B')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'A pays',
          dateTime: DateTime.now(),
          totalAmount: 100,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 100)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'B', amount: 100),
          ],
        ),
        Expense(
          id: 'e2',
          tripId: 'trip1',
          description: 'B pays',
          dateTime: DateTime.now(),
          totalAmount: 100,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'B', amount: 100)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 100),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      expect(result.individualBalances['A'], 0);
      expect(result.individualBalances['B'], 0);
      expect(result.transactions, isEmpty);
    });

    test('people without settlement groups are individual entities', () {
      final persons = [person('A'), person('B'), person('C')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Test',
          dateTime: DateTime.now(),
          totalAmount: 300,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 300)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 100),
            const ExpenseBeneficiary(personId: 'B', amount: 100),
            const ExpenseBeneficiary(personId: 'C', amount: 100),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      // Each person is their own entity
      expect(result.groupBalances.length, 3);
      expect(result.groupBalances['A'], 200);
      expect(result.groupBalances['B'], -100);
      expect(result.groupBalances['C'], -100);
    });

    test('invariant: payer sum equals total', () {
      final expense = Expense(
        id: 'e1',
        tripId: 'trip1',
        description: 'Test',
        dateTime: DateTime.now(),
        totalAmount: 1500,
        currency: 'EUR',
        splitMode: SplitMode.equal,
        payers: [
          const ExpensePayer(personId: 'A', amount: 1000),
          const ExpensePayer(personId: 'B', amount: 500),
        ],
        beneficiaries: [
          const ExpenseBeneficiary(personId: 'A', amount: 500),
          const ExpenseBeneficiary(personId: 'B', amount: 500),
          const ExpenseBeneficiary(personId: 'C', amount: 500),
        ],
      );

      final payerSum = expense.payers.fold<int>(0, (s, p) => s + p.amount);
      final benSum =
          expense.beneficiaries.fold<int>(0, (s, b) => s + b.amount);
      expect(payerSum, expense.totalAmount);
      expect(benSum, expense.totalAmount);
    });

    test('settlement transaction sum equals net flow', () {
      final persons = [person('A'), person('B'), person('C')];
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 'trip1',
          description: 'Test',
          dateTime: DateTime.now(),
          totalAmount: 600,
          currency: 'EUR',
          splitMode: SplitMode.equal,
          payers: [const ExpensePayer(personId: 'A', amount: 600)],
          beneficiaries: [
            const ExpenseBeneficiary(personId: 'A', amount: 200),
            const ExpenseBeneficiary(personId: 'B', amount: 200),
            const ExpenseBeneficiary(personId: 'C', amount: 200),
          ],
        ),
      ];

      final result = calculator.calculate(
        expenses: expenses,
        participants: persons,
        groups: [],
        currency: 'EUR',
      );

      // Sum of all transaction amounts should equal sum of positive balances
      final txSum = result.transactions.fold<int>(0, (s, t) => s + t.amount);
      final positiveSum = result.individualBalances.values
          .where((v) => v > 0)
          .fold<int>(0, (s, v) => s + v);
      expect(txSum, positiveSum);
    });
  });

  group('Money model', () {
    test('arithmetic operations', () {
      const a = Money(amount: 100, currency: 'EUR');
      const b = Money(amount: 50, currency: 'EUR');
      expect((a + b).amount, 150);
      expect((a - b).amount, 50);
      expect((-a).amount, -100);
    });

    test('formatting', () {
      const m = Money(amount: 1050, currency: 'EUR');
      expect(m.formatted, '10.50 EUR');
    });

    test('negative formatting', () {
      const m = Money(amount: -350, currency: 'PLN');
      expect(m.formatted, '-3.50 PLN');
    });

    test('equality', () {
      const a = Money(amount: 100, currency: 'EUR');
      const b = Money(amount: 100, currency: 'EUR');
      const c = Money(amount: 100, currency: 'PLN');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
