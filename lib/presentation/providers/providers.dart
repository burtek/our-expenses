import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/settlement_calculator.dart';
import '../../data/repositories/sqlite_repositories.dart';

// Repository providers
final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => SqliteTripRepository(),
);

final personRepositoryProvider = Provider<PersonRepository>(
  (ref) => SqlitePersonRepository(),
);

final settlementGroupRepositoryProvider = Provider<SettlementGroupRepository>(
  (ref) => SqliteSettlementGroupRepository(),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => SqliteExpenseRepository(),
);

final settlementCalculatorProvider = Provider<SettlementCalculator>(
  (ref) => const SettlementCalculator(),
);

// Trip providers
final tripsProvider = AsyncNotifierProvider<TripsNotifier, List<Trip>>(
  TripsNotifier.new,
);

class TripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    return ref.read(tripRepositoryProvider).getAllTrips();
  }

  Future<void> addTrip(Trip trip) async {
    await ref.read(tripRepositoryProvider).insertTrip(trip);
    ref.invalidateSelf();
  }

  Future<void> updateTrip(Trip trip) async {
    await ref.read(tripRepositoryProvider).updateTrip(trip);
    ref.invalidateSelf();
  }

  Future<void> deleteTrip(String id) async {
    await ref.read(tripRepositoryProvider).deleteTrip(id);
    ref.invalidateSelf();
  }
}

// Persons provider (per trip)
final personsProvider =
    AsyncNotifierProvider.family<PersonsNotifier, List<Person>, String>(
      PersonsNotifier.new,
    );

class PersonsNotifier extends FamilyAsyncNotifier<List<Person>, String> {
  @override
  Future<List<Person>> build(String arg) async {
    return ref.read(personRepositoryProvider).getPersonsByTrip(arg);
  }

  Future<void> addPerson(Person person) async {
    await ref.read(personRepositoryProvider).insertPerson(person);
    ref.invalidateSelf();
  }

  Future<void> updatePerson(Person person) async {
    await ref.read(personRepositoryProvider).updatePerson(person);
    ref.invalidateSelf();
  }

  Future<void> deletePerson(String id) async {
    await ref.read(personRepositoryProvider).deletePerson(id);
    ref.invalidateSelf();
  }
}

// Settlement groups provider (per trip)
final settlementGroupsProvider =
    AsyncNotifierProvider.family<
      SettlementGroupsNotifier,
      List<SettlementGroup>,
      String
    >(SettlementGroupsNotifier.new);

class SettlementGroupsNotifier
    extends FamilyAsyncNotifier<List<SettlementGroup>, String> {
  @override
  Future<List<SettlementGroup>> build(String arg) async {
    return ref.read(settlementGroupRepositoryProvider).getGroupsByTrip(arg);
  }

  Future<void> addGroup(SettlementGroup group) async {
    await ref.read(settlementGroupRepositoryProvider).insertGroup(group);
    ref.invalidateSelf();
  }

  Future<void> updateGroup(SettlementGroup group) async {
    await ref.read(settlementGroupRepositoryProvider).updateGroup(group);
    ref.invalidateSelf();
  }

  Future<void> deleteGroup(String id) async {
    await ref.read(settlementGroupRepositoryProvider).deleteGroup(id);
    ref.invalidateSelf();
  }
}

// Expenses provider (per trip)
final expensesProvider =
    AsyncNotifierProvider.family<ExpensesNotifier, List<Expense>, String>(
      ExpensesNotifier.new,
    );

class ExpensesNotifier extends FamilyAsyncNotifier<List<Expense>, String> {
  @override
  Future<List<Expense>> build(String arg) async {
    return ref.read(expenseRepositoryProvider).getExpensesByTrip(arg);
  }

  Future<void> addExpense(Expense expense) async {
    await ref.read(expenseRepositoryProvider).insertExpense(expense);
    ref.invalidateSelf();
  }

  Future<void> updateExpense(Expense expense) async {
    await ref.read(expenseRepositoryProvider).updateExpense(expense);
    ref.invalidateSelf();
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).deleteExpense(id);
    ref.invalidateSelf();
  }
}

// Settlement result provider (per trip)
final settlementResultProvider =
    FutureProvider.family<SettlementResult, String>((ref, tripId) async {
      final expenses = await ref.watch(expensesProvider(tripId).future);
      final participants = await ref.watch(personsProvider(tripId).future);
      final groups = await ref.watch(settlementGroupsProvider(tripId).future);

      // Get trip currency
      final trip = await ref.read(tripRepositoryProvider).getTripById(tripId);
      final currency = trip?.currency ?? 'EUR';

      final calculator = ref.read(settlementCalculatorProvider);
      return calculator.calculate(
        expenses: expenses,
        participants: participants,
        groups: groups,
        currency: currency,
      );
    });
