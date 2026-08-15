import 'package:sqflite/sqflite.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../database/database_helper.dart';

class SqliteTripRepository implements TripRepository {
  @override
  Future<List<Trip>> getAllTrips() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('trips', orderBy: 'created_at DESC');
    return maps.map(_mapToTrip).toList();
  }

  @override
  Future<Trip?> getTripById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _mapToTrip(maps.first);
  }

  @override
  Future<void> insertTrip(Trip trip) async {
    final db = await DatabaseHelper.database;
    await db.insert('trips', {
      'id': trip.id,
      'name': trip.name,
      'description': trip.description,
      'currency': trip.currency,
      'created_at': trip.createdAt.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'trips',
      {
        'name': trip.name,
        'description': trip.description,
        'currency': trip.currency,
      },
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  @override
  Future<void> deleteTrip(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Trip _mapToTrip(Map<String, dynamic> map) => Trip(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    currency: map['currency'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

class SqlitePersonRepository implements PersonRepository {
  @override
  Future<List<Person>> getPersonsByTrip(String tripId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'persons',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return maps
        .map(
          (m) => Person(
            id: m['id'] as String,
            displayName: m['display_name'] as String,
            tripId: m['trip_id'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<void> insertPerson(Person person) async {
    final db = await DatabaseHelper.database;
    await db.insert('persons', {
      'id': person.id,
      'display_name': person.displayName,
      'trip_id': person.tripId,
    });
  }

  @override
  Future<void> updatePerson(Person person) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'persons',
      {'display_name': person.displayName},
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  @override
  Future<void> deletePerson(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteSettlementGroupRepository implements SettlementGroupRepository {
  @override
  Future<List<SettlementGroup>> getGroupsByTrip(String tripId) async {
    final db = await DatabaseHelper.database;
    final groups = await db.query(
      'settlement_groups',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    final result = <SettlementGroup>[];
    for (final g in groups) {
      final members = await db.query(
        'settlement_group_members',
        where: 'group_id = ?',
        whereArgs: [g['id']],
      );
      result.add(
        SettlementGroup(
          id: g['id'] as String,
          name: g['name'] as String,
          tripId: g['trip_id'] as String,
          memberIds: members.map((m) => m['person_id'] as String).toList(),
        ),
      );
    }
    return result;
  }

  @override
  Future<void> insertGroup(SettlementGroup group) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.insert('settlement_groups', {
        'id': group.id,
        'name': group.name,
        'trip_id': group.tripId,
      });
      for (final memberId in group.memberIds) {
        await txn.insert('settlement_group_members', {
          'group_id': group.id,
          'person_id': memberId,
        });
      }
    });
  }

  @override
  Future<void> updateGroup(SettlementGroup group) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'settlement_groups',
        {'name': group.name},
        where: 'id = ?',
        whereArgs: [group.id],
      );
      await txn.delete(
        'settlement_group_members',
        where: 'group_id = ?',
        whereArgs: [group.id],
      );
      for (final memberId in group.memberIds) {
        await txn.insert('settlement_group_members', {
          'group_id': group.id,
          'person_id': memberId,
        });
      }
    });
  }

  @override
  Future<void> deleteGroup(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('settlement_groups', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteExpenseRepository implements ExpenseRepository {
  @override
  Future<List<Expense>> getExpensesByTrip(String tripId) async {
    final db = await DatabaseHelper.database;
    final expenses = await db.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'date_time DESC',
    );
    final result = <Expense>[];
    for (final e in expenses) {
      result.add(await _buildExpense(db, e));
    }
    return result;
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _buildExpense(db, maps.first);
  }

  @override
  Future<void> insertExpense(Expense expense) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.insert('expenses', {
        'id': expense.id,
        'trip_id': expense.tripId,
        'description': expense.description,
        'date_time': expense.dateTime.millisecondsSinceEpoch,
        'total_amount': expense.totalAmount,
        'currency': expense.currency,
        'split_mode': expense.splitMode.name,
      });
      for (final p in expense.payers) {
        await txn.insert('expense_payers', {
          'expense_id': expense.id,
          'person_id': p.personId,
          'amount': p.amount,
        });
      }
      for (final b in expense.beneficiaries) {
        await txn.insert('expense_beneficiaries', {
          'expense_id': expense.id,
          'person_id': b.personId,
          'amount': b.amount,
          'shares': b.shares,
        });
      }
    });
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'expenses',
        {
          'description': expense.description,
          'date_time': expense.dateTime.millisecondsSinceEpoch,
          'total_amount': expense.totalAmount,
          'currency': expense.currency,
          'split_mode': expense.splitMode.name,
        },
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      await txn.delete(
        'expense_payers',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );
      await txn.delete(
        'expense_beneficiaries',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );
      for (final p in expense.payers) {
        await txn.insert('expense_payers', {
          'expense_id': expense.id,
          'person_id': p.personId,
          'amount': p.amount,
        });
      }
      for (final b in expense.beneficiaries) {
        await txn.insert('expense_beneficiaries', {
          'expense_id': expense.id,
          'person_id': b.personId,
          'amount': b.amount,
          'shares': b.shares,
        });
      }
    });
  }

  @override
  Future<void> deleteExpense(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<Expense> _buildExpense(Database db, Map<String, dynamic> e) async {
    final payers = await db.query(
      'expense_payers',
      where: 'expense_id = ?',
      whereArgs: [e['id']],
    );
    final beneficiaries = await db.query(
      'expense_beneficiaries',
      where: 'expense_id = ?',
      whereArgs: [e['id']],
    );
    return Expense(
      id: e['id'] as String,
      tripId: e['trip_id'] as String,
      description: e['description'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(e['date_time'] as int),
      totalAmount: e['total_amount'] as int,
      currency: e['currency'] as String,
      splitMode: SplitMode.values.byName(e['split_mode'] as String),
      payers: payers
          .map(
            (p) => ExpensePayer(
              personId: p['person_id'] as String,
              amount: p['amount'] as int,
            ),
          )
          .toList(),
      beneficiaries: beneficiaries
          .map(
            (b) => ExpenseBeneficiary(
              personId: b['person_id'] as String,
              amount: b['amount'] as int,
              shares: b['shares'] as int?,
            ),
          )
          .toList(),
    );
  }
}
