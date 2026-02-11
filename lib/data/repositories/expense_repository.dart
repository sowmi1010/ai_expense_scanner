import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/expense_model.dart';

class DailyTotal {
  final DateTime day; // start of day
  final double total;

  DailyTotal({required this.day, required this.total});
}

class CategoryTotal {
  final String category;
  final double total;

  CategoryTotal({required this.category, required this.total});
}

class ExpenseRepository {
  ExpenseRepository._internal();
  static final ExpenseRepository instance = ExpenseRepository._internal();

  /// Notifies UI when expenses are added/changed
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('expenses', expense.toMap());
    changes.value++;
    return id;
  }

  Future<double> sumByDateRange(DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
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

  Future<int> countByDateRange(DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
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

  // ✅ Export helper: fetch expenses in a date range
  Future<List<ExpenseModel>> getExpensesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.query(
      'expenses',
      where:
          'datetime(created_at) >= datetime(?) AND datetime(created_at) < datetime(?)',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'datetime(created_at) DESC',
    );

    return rows.map(ExpenseModel.fromMap).toList();
  }

  // =========================
  // CHART QUERIES
  // =========================

  /// Last N days totals (including today). Returns one item per day (0 if no spend).
  Future<List<DailyTotal>> getDailyTotals({int days = 7}) async {
    final db = await AppDatabase.instance.database;

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

    final map = <String, double>{};
    for (final r in rows) {
      final day = (r['day'] as String?) ?? '';
      final total = (r['total'] as num).toDouble();
      map[day] = total;
    }

    final out = <DailyTotal>[];
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = d.toIso8601String().substring(0, 10); // yyyy-MM-dd
      out.add(
        DailyTotal(day: DateTime(d.year, d.month, d.day), total: map[key] ?? 0),
      );
    }

    return out;
  }

  /// Category totals within a date range (good for month pie).
  Future<List<CategoryTotal>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final db = await AppDatabase.instance.database;

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

    return rows
        .map(
          (r) => CategoryTotal(
            category: (r['category'] as String?) ?? 'Others',
            total: (r['total'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<double> sumByDateAndCategory(
    DateTime start,
    DateTime end,
    String? category,
  ) async {
    final db = await AppDatabase.instance.database;

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
