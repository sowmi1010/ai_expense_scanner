import '../database/app_database.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repo.dart';
import '../security/sensitive_data_cipher.dart';

abstract class ExpenseLocalService {
  Future<int> insertExpense(ExpenseModel expense);

  Future<int> updateExpense(ExpenseModel expense);

  Future<int> deleteExpense(int expenseId);

  Future<double> sumByDateRange(DateTime start, DateTime end);

  Future<int> countByDateRange(DateTime start, DateTime end);

  Future<List<ExpenseModel>> getExpensesInRange(DateTime start, DateTime end);

  Future<List<DailyTotal>> getDailyTotals({int days = 7});

  Future<List<CategoryTotal>> getCategoryTotals(DateTime start, DateTime end);

  Future<double> sumByDateAndCategory(
    DateTime start,
    DateTime end,
    String? category,
  );
}

class MemoryExpenseLocalService implements ExpenseLocalService {
  final List<ExpenseModel> _expenses = <ExpenseModel>[];
  int _nextId = 1;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isInRange(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  static String _dayKey(DateTime d) => _startOfDay(d).toIso8601String();

  ExpenseModel _copyWithId(ExpenseModel expense, int id) {
    return ExpenseModel(
      id: id,
      amount: expense.amount,
      merchant: expense.merchant,
      category: expense.category,
      paymentMode: expense.paymentMode,
      createdAt: expense.createdAt,
      receiptImagePath: expense.receiptImagePath,
      rawOcrText: expense.rawOcrText,
    );
  }

  @override
  Future<int> insertExpense(ExpenseModel expense) async {
    final id = _nextId++;
    _expenses.add(_copyWithId(expense, id));
    return id;
  }

  @override
  Future<int> updateExpense(ExpenseModel expense) async {
    final id = expense.id;
    if (id == null) return 0;

    final index = _expenses.indexWhere((item) => item.id == id);
    if (index == -1) return 0;

    _expenses[index] = expense;
    return 1;
  }

  @override
  Future<int> deleteExpense(int expenseId) async {
    final before = _expenses.length;
    _expenses.removeWhere((item) => item.id == expenseId);
    return before == _expenses.length ? 0 : 1;
  }

  @override
  Future<double> sumByDateRange(DateTime start, DateTime end) async {
    return _expenses
        .where((item) => _isInRange(item.createdAt, start, end))
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  @override
  Future<int> countByDateRange(DateTime start, DateTime end) async {
    return _expenses
        .where((item) => _isInRange(item.createdAt, start, end))
        .length;
  }

  @override
  Future<List<ExpenseModel>> getExpensesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final out = _expenses
        .where((item) => _isInRange(item.createdAt, start, end))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<ExpenseModel>.unmodifiable(out);
  }

  @override
  Future<List<DailyTotal>> getDailyTotals({int days = 7}) async {
    final now = DateTime.now();
    final start = _startOfDay(now).subtract(Duration(days: days - 1));
    final end = _startOfDay(now).add(const Duration(days: 1));

    final totalsByDay = <String, double>{};
    for (final item in _expenses) {
      if (!_isInRange(item.createdAt, start, end)) continue;
      final key = _dayKey(item.createdAt);
      totalsByDay[key] = (totalsByDay[key] ?? 0) + item.amount;
    }

    final out = <DailyTotal>[];
    for (int i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      out.add(
        DailyTotal(
          day: day,
          total: totalsByDay[_dayKey(day)] ?? 0,
        ),
      );
    }
    return List<DailyTotal>.unmodifiable(out);
  }

  @override
  Future<List<CategoryTotal>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final totals = <String, double>{};
    for (final item in _expenses) {
      if (!_isInRange(item.createdAt, start, end)) continue;
      totals[item.category] = (totals[item.category] ?? 0) + item.amount;
    }

    final out = totals.entries
        .map((e) => CategoryTotal(category: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return List<CategoryTotal>.unmodifiable(out);
  }

  @override
  Future<double> sumByDateAndCategory(
    DateTime start,
    DateTime end,
    String? category,
  ) async {
    return _expenses
        .where((item) => _isInRange(item.createdAt, start, end))
        .where((item) => category == null || item.category == category)
        .fold<double>(0, (sum, item) => sum + item.amount);
  }
}

class SqliteExpenseLocalService implements ExpenseLocalService {
  final AppDatabase _database;
  final SensitiveDataCipher _cipher;

  SqliteExpenseLocalService({
    required AppDatabase database,
    SensitiveDataCipher? cipher,
  }) : _database = database,
       _cipher = cipher ?? SensitiveDataCipher();

  Future<Map<String, dynamic>> _toEncryptedMap(ExpenseModel expense) async {
    final map = expense.toMap();
    map['merchant'] = (await _cipher.encryptNullable(expense.merchant)) ?? '';
    map['raw_ocr_text'] = await _cipher.encryptNullable(expense.rawOcrText);
    return map;
  }

  Future<ExpenseModel> _toDecryptedExpense(
    Map<String, Object?> encryptedRow,
  ) async {
    final row = Map<String, dynamic>.from(encryptedRow);
    row['merchant'] =
        (await _cipher.decryptNullable(row['merchant'] as String?)) ?? '';
    row['raw_ocr_text'] = await _cipher.decryptNullable(
      row['raw_ocr_text'] as String?,
    );
    return ExpenseModel.fromMap(row);
  }

  @override
  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await _database.database;
    final encryptedMap = await _toEncryptedMap(expense);
    return db.insert('expenses', encryptedMap);
  }

  @override
  Future<int> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) return 0;

    final db = await _database.database;
    final encryptedMap = await _toEncryptedMap(expense);
    return db.update(
      'expenses',
      encryptedMap,
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  @override
  Future<int> deleteExpense(int expenseId) async {
    final db = await _database.database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  @override
  Future<double> sumByDateRange(DateTime start, DateTime end) async {
    final db = await _database.database;
    final res = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (res.first['total'] as num).toDouble();
  }

  @override
  Future<int> countByDateRange(DateTime start, DateTime end) async {
    final db = await _database.database;
    final res = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt
      FROM expenses
      WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (res.first['cnt'] as num).toInt();
  }

  @override
  Future<List<ExpenseModel>> getExpensesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _database.database;

    final rows = await db.query(
      'expenses',
      where:
          'datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'datetime(created_at) DESC',
    );

    final decryptedRows = await Future.wait(
      rows.map((row) => _toDecryptedExpense(row)),
    );

    return List<ExpenseModel>.unmodifiable(decryptedRows);
  }

  @override
  Future<List<DailyTotal>> getDailyTotals({int days = 7}) async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final end = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT substr(created_at, 1, 10) AS day, IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
      GROUP BY substr(created_at, 1, 10)
      ORDER BY day ASC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    final totalsByDay = <String, double>{};
    for (final row in rows) {
      final day = (row['day'] as String?) ?? '';
      totalsByDay[day] = (row['total'] as num).toDouble();
    }

    final out = <DailyTotal>[];
    for (int i = 0; i < days; i++) {
      final currentDay = start.add(Duration(days: i));
      final key = currentDay.toIso8601String().substring(0, 10);
      out.add(
        DailyTotal(
          day: DateTime(currentDay.year, currentDay.month, currentDay.day),
          total: totalsByDay[key] ?? 0,
        ),
      );
    }
    return List<DailyTotal>.unmodifiable(out);
  }

  @override
  Future<List<CategoryTotal>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _database.database;

    final rows = await db.rawQuery(
      '''
      SELECT category, IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)
      GROUP BY category
      ORDER BY total DESC
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return List<CategoryTotal>.unmodifiable(
      rows
          .map(
            (row) => CategoryTotal(
              category: (row['category'] as String?) ?? 'Others',
              total: (row['total'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<double> sumByDateAndCategory(
    DateTime start,
    DateTime end,
    String? category,
  ) async {
    final db = await _database.database;

    final res = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE datetime(created_at) >= datetime(?)
        AND datetime(created_at) < datetime(?)
        ${category != null ? 'AND category = ?' : ''}
    ''',
      category != null
          ? [start.toIso8601String(), end.toIso8601String(), category]
          : [start.toIso8601String(), end.toIso8601String()],
    );

    return (res.first['total'] as num).toDouble();
  }
}
