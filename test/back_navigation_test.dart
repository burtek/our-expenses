import 'package:expense_settler/app.dart';
import 'package:expense_settler/domain/models/models.dart';
import 'package:expense_settler/domain/repositories/repositories.dart';
import 'package:expense_settler/presentation/providers/providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final trip = Trip(
    id: 'trip-1',
    name: 'Summer Trip',
    currency: 'EUR',
    createdAt: DateTime(2024),
  );
  final person = Person(
    id: 'person-1',
    displayName: 'Alex',
    tripId: trip.id,
  );

  ProviderScope buildApp({required String initialLocation}) => ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(
            _FakeTripRepository([trip]),
          ),
          personRepositoryProvider.overrideWithValue(
            _FakePersonRepository({
              trip.id: [person]
            }),
          ),
          settlementGroupRepositoryProvider.overrideWithValue(
            _FakeSettlementGroupRepository(),
          ),
          expenseRepositoryProvider.overrideWithValue(
            _FakeExpenseRepository(),
          ),
        ],
        child: ExpenseSettlerApp(
          routerConfig: createRouter(initialLocation: initialLocation),
        ),
      );

  testWidgets('deep-linked trip detail back navigates to trips list', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(initialLocation: '/trip/${trip.id}'));
    await tester.pumpAndSettle();

    expect(find.text('Summer Trip'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Trips'), findsOneWidget);
  });

  testWidgets('deep-linked add expense system back navigates to trip detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(initialLocation: '/trip/${trip.id}/add-expense'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Summer Trip'), findsOneWidget);
  });

  testWidgets('stack back navigation returns through add expense and trip', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(initialLocation: '/'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Summer Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Summer Trip'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add Expense'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Summer Trip'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Trips'), findsOneWidget);
  });
}

class _FakeTripRepository implements TripRepository {
  _FakeTripRepository(List<Trip> trips)
      : _trips = {for (final trip in trips) trip.id: trip};

  final Map<String, Trip> _trips;

  @override
  Future<void> deleteTrip(String id) async {
    _trips.remove(id);
  }

  @override
  Future<List<Trip>> getAllTrips() async => _trips.values.toList();

  @override
  Future<Trip?> getTripById(String id) async => _trips[id];

  @override
  Future<void> insertTrip(Trip trip) async {
    _trips[trip.id] = trip;
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    _trips[trip.id] = trip;
  }
}

class _FakePersonRepository implements PersonRepository {
  _FakePersonRepository(this._personsByTrip);

  final Map<String, List<Person>> _personsByTrip;

  @override
  Future<void> deletePerson(String id) async {
    for (final persons in _personsByTrip.values) {
      persons.removeWhere((person) => person.id == id);
    }
  }

  @override
  Future<List<Person>> getPersonsByTrip(String tripId) async =>
      _personsByTrip[tripId] ?? [];

  @override
  Future<void> insertPerson(Person person) async {
    _personsByTrip.putIfAbsent(person.tripId, () => []).add(person);
  }

  @override
  Future<void> updatePerson(Person person) async {
    final persons = _personsByTrip[person.tripId];
    if (persons == null) return;

    final index = persons.indexWhere((current) => current.id == person.id);
    if (index == -1) return;
    persons[index] = person;
  }
}

class _FakeSettlementGroupRepository implements SettlementGroupRepository {
  @override
  Future<void> deleteGroup(String id) async {}

  @override
  Future<List<SettlementGroup>> getGroupsByTrip(String tripId) async => [];

  @override
  Future<void> insertGroup(SettlementGroup group) async {}

  @override
  Future<void> updateGroup(SettlementGroup group) async {}
}

class _FakeExpenseRepository implements ExpenseRepository {
  final Map<String, Expense> _expenses = {};

  @override
  Future<void> deleteExpense(String id) async {
    _expenses.remove(id);
  }

  @override
  Future<Expense?> getExpenseById(String id) async => _expenses[id];

  @override
  Future<List<Expense>> getExpensesByTrip(String tripId) async =>
      _expenses.values.where((expense) => expense.tripId == tripId).toList();

  @override
  Future<void> insertExpense(Expense expense) async {
    _expenses[expense.id] = expense;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    _expenses[expense.id] = expense;
  }
}
