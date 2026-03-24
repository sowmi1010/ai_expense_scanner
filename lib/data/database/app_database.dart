import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const defaultDbName = 'expense_ai.db';
  static const defaultDbVersion = 2;

  final String dbName;
  final int dbVersion;

  AppDatabase({this.dbName = defaultDbName, this.dbVersion = defaultDbVersion});

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);

    return openDatabase(
      path,
      version: dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            merchant TEXT NOT NULL,
            category TEXT NOT NULL,
            payment_mode TEXT NOT NULL DEFAULT 'Cash',
            created_at TEXT NOT NULL,
            receipt_image_path TEXT,
            raw_ocr_text TEXT
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_expenses_created_at ON expenses(created_at);',
        );
        await db.execute(
          'CREATE INDEX idx_expenses_category ON expenses(category);',
        );
        await db.execute(
          'CREATE INDEX idx_expenses_payment_mode ON expenses(payment_mode);',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE expenses ADD COLUMN payment_mode TEXT NOT NULL DEFAULT 'Cash';",
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_expenses_payment_mode ON expenses(payment_mode);',
          );
        }
      },
    );
  }
}
