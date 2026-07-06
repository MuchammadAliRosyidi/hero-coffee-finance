import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'hero_coffee_finance.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            outlet_id TEXT NOT NULL DEFAULT 'main'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE transactions ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "UPDATE transactions SET created_at = strftime('%Y-%m-%dT%H:%M:%f', 'now') WHERE created_at = ''",
          );
        }

        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE transactions ADD COLUMN outlet_id TEXT NOT NULL DEFAULT 'main'",
          );
        }
      },
    );
  }
}
