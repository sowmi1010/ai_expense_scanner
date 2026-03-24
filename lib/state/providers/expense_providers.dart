import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/expense_options.dart';
import '../../data/database/app_database.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/security/sensitive_data_cipher.dart';
import '../../data/services/expense_local_service.dart';
import '../../data/services/expense_sync_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final sensitiveDataCipherProvider = Provider<SensitiveDataCipher>(
  (ref) => SensitiveDataCipher(),
);

final expenseLocalServiceProvider = Provider<ExpenseLocalService>(
  (ref) => kIsWeb
      ? MemoryExpenseLocalService()
      : SqliteExpenseLocalService(
          database: ref.watch(appDatabaseProvider),
          cipher: ref.watch(sensitiveDataCipherProvider),
        ),
);

final expenseSyncServiceProvider = Provider<ExpenseSyncService>(
  (ref) => const NoopExpenseSyncService(),
);

final expenseRepositoryProvider = ChangeNotifierProvider<ExpenseRepo>(
  (ref) => ExpenseRepository(
    localService: ref.watch(expenseLocalServiceProvider),
    syncService: ref.watch(expenseSyncServiceProvider),
  ),
);

final expenseSyncStateProvider = Provider<OfflineSyncState>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.syncState;
});

class DashboardStats {
  final double todayTotal;
  final int todayCount;
  final double monthTotal;

  const DashboardStats({
    required this.todayTotal,
    required this.todayCount,
    required this.monthTotal,
  });

  static const empty = DashboardStats(
    todayTotal: 0,
    todayCount: 0,
    monthTotal: 0,
  );
}

class MonthlyOverviewData {
  final List<CategoryTotal> categoryTotals;
  final List<ExpenseModel> expenses;
  final double total;

  const MonthlyOverviewData({
    required this.categoryTotals,
    required this.expenses,
    required this.total,
  });

  static const empty = MonthlyOverviewData(
    categoryTotals: [],
    expenses: [],
    total: 0,
  );
}

DateTime _startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime _startOfNextDay(DateTime date) =>
    _startOfDay(date).add(const Duration(days: 1));

DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

DateTime _startOfNextMonth(DateTime date) =>
    DateTime(date.year, date.month + 1, 1);

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();

  final todayStart = _startOfDay(now);
  final tomorrowStart = _startOfNextDay(now);
  final monthStart = _startOfMonth(now);
  final nextMonthStart = _startOfNextMonth(now);

  final todayTotal = await repo.sumByDateRange(todayStart, tomorrowStart);
  final todayCount = await repo.countByDateRange(todayStart, tomorrowStart);
  final monthTotal = await repo.sumByDateRange(monthStart, nextMonthStart);

  return DashboardStats(
    todayTotal: todayTotal,
    todayCount: todayCount,
    monthTotal: monthTotal,
  );
});

final weeklySpendTrendProvider = FutureProvider.family<List<DailyTotal>, int>((
  ref,
  days,
) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getDailyTotals(days: days);
});

final currentMonthCategoryTotalsProvider = FutureProvider<List<CategoryTotal>>((
  ref,
) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final monthStart = _startOfMonth(now);
  final nextMonthStart = _startOfNextMonth(now);
  return repo.getCategoryTotals(monthStart, nextMonthStart);
});

final monthlyOverviewProvider =
    FutureProvider.family<MonthlyOverviewData, DateTime>((ref, month) async {
      final repo = ref.watch(expenseRepositoryProvider);
      final monthStart = DateTime(month.year, month.month, 1);
      final nextMonthStart = DateTime(month.year, month.month + 1, 1);

      final rawCategoryTotals = await repo.getCategoryTotals(
        monthStart,
        nextMonthStart,
      );
      final expenses = await repo.getExpensesInRange(
        monthStart,
        nextMonthStart,
      );

      final totalsByCategory = <String, double>{};
      for (final item in rawCategoryTotals) {
        totalsByCategory[item.category] =
            (totalsByCategory[item.category] ?? 0) + item.total;
      }

      final orderedRows = <CategoryTotal>[
        for (final name in ExpenseOptions.categories)
          CategoryTotal(category: name, total: totalsByCategory[name] ?? 0),
      ];

      final extras =
          totalsByCategory.keys
              .where((name) => !ExpenseOptions.categories.contains(name))
              .toList()
            ..sort(
              (a, b) => (totalsByCategory[b] ?? 0).compareTo(
                totalsByCategory[a] ?? 0,
              ),
            );

      for (final name in extras) {
        orderedRows.add(
          CategoryTotal(category: name, total: totalsByCategory[name] ?? 0),
        );
      }

      final total = orderedRows.fold<double>(0, (sum, e) => sum + e.total);

      return MonthlyOverviewData(
        categoryTotals: orderedRows,
        expenses: expenses,
        total: total,
      );
    });
