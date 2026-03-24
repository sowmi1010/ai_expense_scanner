import 'package:flutter/foundation.dart';

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

class OfflineSyncState {
  final bool syncEnabled;
  final bool syncInProgress;
  final int pendingOperations;
  final DateTime? lastSyncAttemptAt;
  final String? lastSyncError;

  const OfflineSyncState({
    required this.syncEnabled,
    required this.syncInProgress,
    required this.pendingOperations,
    this.lastSyncAttemptAt,
    this.lastSyncError,
  });

  bool get hasPendingOperations => pendingOperations > 0;

  static const disabled = OfflineSyncState(
    syncEnabled: false,
    syncInProgress: false,
    pendingOperations: 0,
  );
}

abstract class ExpenseRepo extends ChangeNotifier {
  Future<int> insertExpense(ExpenseModel expense);

  Future<int> updateExpense(ExpenseModel expense);

  Future<int> deleteExpense(int id);

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

  OfflineSyncState get syncState;

  Future<void> retryPendingSync();
}
