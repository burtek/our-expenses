import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'expense_settler.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        currency TEXT NOT NULL DEFAULT 'EUR',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE persons (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        trip_id TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settlement_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        trip_id TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settlement_group_members (
        group_id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        PRIMARY KEY (group_id, person_id),
        FOREIGN KEY (group_id) REFERENCES settlement_groups(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        description TEXT NOT NULL,
        date_time INTEGER NOT NULL,
        total_amount INTEGER NOT NULL,
        currency TEXT NOT NULL,
        split_mode TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_payers (
        expense_id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        PRIMARY KEY (expense_id, person_id),
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_beneficiaries (
        expense_id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        shares INTEGER,
        PRIMARY KEY (expense_id, person_id),
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE
      )
    ''');
  }

  /// For testing: allows injecting a database instance
  static void setDatabase(Database db) {
    _database = db;
  }
}
