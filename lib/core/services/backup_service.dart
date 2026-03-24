import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BackupService {
  final String dbName;

  BackupService({this.dbName = 'expense_ai.db'});

  /// Copies the SQLite DB to a new file (safe to share)
  Future<File> backupDatabaseToFile({
    String fileName = 'expense_ai_backup.db',
  }) async {
    final dbPath = await getDatabasesPath();
    final source = File(p.join(dbPath, dbName));

    if (!await source.exists()) {
      throw Exception('Database not found at: ${source.path}');
    }

    // Use databasesPath itself as destination (safe), with new name
    final dest = File(p.join(dbPath, fileName));

    // Overwrite if exists
    if (await dest.exists()) {
      await dest.delete();
    }

    return source.copy(dest.path);
  }
}
