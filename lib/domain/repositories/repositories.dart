import '../models/models.dart';

abstract class TripRepository {
  Future<List<Trip>> getAllTrips();
  Future<Trip?> getTripById(String id);
  Future<void> insertTrip(Trip trip);
  Future<void> updateTrip(Trip trip);
  Future<void> deleteTrip(String id);
}

abstract class PersonRepository {
  Future<List<Person>> getPersonsByTrip(String tripId);
  Future<void> insertPerson(Person person);
  Future<void> updatePerson(Person person);
  Future<void> deletePerson(String id);
}

abstract class SettlementGroupRepository {
  Future<List<SettlementGroup>> getGroupsByTrip(String tripId);
  Future<void> insertGroup(SettlementGroup group);
  Future<void> updateGroup(SettlementGroup group);
  Future<void> deleteGroup(String id);
}

abstract class ExpenseRepository {
  Future<List<Expense>> getExpensesByTrip(String tripId);
  Future<Expense?> getExpenseById(String id);
  Future<void> insertExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}
