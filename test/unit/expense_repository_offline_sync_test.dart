import 'package:ai_expense_scanner/data/models/expense_model.dart';
import 'package:ai_expense_scanner/data/repositories/expense_repository.dart';
import 'package:ai_expense_scanner/data/services/expense_local_service.dart';
import 'package:ai_expense_scanner/data/services/expense_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryExpenseLocalService implements ExpenseLocalService {
  final Map<int, ExpenseModel> _store = {};
  int _nextId = 1;

  @override
  Future<int> insertExpense(ExpenseModel expense) async {
    final id = _nextId++;
    _store[id] = ExpenseModel(
      id: id,
      amount: expense.amount,
      merchant: expense.merchant,
      category: expense.category,
      paymentMode: expense.paymentMode,
      createdAt: expense.createdAt,
      receiptImagePath: expense.receiptImagePath,
      rawOcrText: expense.rawOcrText,
    );
    return id;
  }

  @override
  Future<int> updateExpense(ExpenseModel expense) async {
    final id = expense.id;
    if (id == null || !_store.containsKey(id)) return 0;
    _store[id] = expense;
    return 1;
  }

  @override
  Future<int> deleteExpense(int expenseId) async {
    return _store.remove(expenseId) == null ? 0 : 1;
  }

  @override
  Future<double> sumByDateRange(DateTime start, DateTime end) async {
    return _store.values
        .where((e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(end))
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  @override
  Future<int> countByDateRange(DateTime start, DateTime end) async {
    return _store.values
        .where((e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(end))
        .length;
  }

  @override
  Future<List<ExpenseModel>> getExpensesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final items =
        _store.values
            .where(
              (e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(end),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<ExpenseModel>.unmodifiable(items);
  }

  @override
  Future<List<DailyTotal>> getDailyTotals({int days = 7}) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final out = <DailyTotal>[];
    for (int i = 0; i < days; i++) {
      final dayStart = start.add(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final total = _store.values
          .where(
            (e) =>
                !e.createdAt.isBefore(dayStart) && e.createdAt.isBefore(dayEnd),
          )
          .fold<double>(0, (sum, e) => sum + e.amount);
      out.add(
        DailyTotal(
          day: DateTime(dayStart.year, dayStart.month, dayStart.day),
          total: total,
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
    final totalsByCategory = <String, double>{};

    for (final expense in _store.values) {
      if (expense.createdAt.isBefore(start) ||
          !expense.createdAt.isBefore(end)) {
        continue;
      }
      totalsByCategory[expense.category] =
          (totalsByCategory[expense.category] ?? 0) + expense.amount;
    }

    final out =
        totalsByCategory.entries
            .map(
              (entry) => CategoryTotal(category: entry.key, total: entry.value),
            )
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
    return _store.values
        .where((expense) {
          if (expense.createdAt.isBefore(start) ||
              !expense.createdAt.isBefore(end)) {
            return false;
          }
          if (category == null) return true;
          return expense.category == category;
        })
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }
}

class _FlakySyncService implements ExpenseSyncService {
  bool failSync = true;
  final List<ExpenseModel> upserted = [];
  final List<int> deleted = [];

  @override
  bool get isEnabled => true;

  @override
  Future<void> upsertExpense(ExpenseModel expense) async {
    if (failSync) {
      throw Exception('offline');
    }
    upserted.add(expense);
  }

  @override
  Future<void> deleteExpense(int expenseId) async {
    if (failSync) {
      throw Exception('offline');
    }
    deleted.add(expenseId);
  }
}

void main() {
  group('ExpenseRepository offline sync queue', () {
    test('keeps local insert and queues sync when remote is down', () async {
      final local = _MemoryExpenseLocalService();
      final sync = _FlakySyncService()..failSync = true;
      final repository = ExpenseRepository(
        localService: local,
        syncService: sync,
      );

      final id = await repository.insertExpense(
        ExpenseModel(
          amount: 450,
          merchant: 'Store',
          category: 'Groceries',
          createdAt: DateTime(2026, 3, 23, 10, 0),
        ),
      );

      expect(id, 1);
      expect(sync.upserted, isEmpty);

      await repository.retryPendingSync();

      final state = repository.syncState;
      expect(state.syncEnabled, isTrue);
      expect(state.hasPendingOperations, isTrue);
      expect(state.pendingOperations, 1);
      expect(state.lastSyncError, isNotNull);
    });

    test('retries pending operations when remote becomes available', () async {
      final local = _MemoryExpenseLocalService();
      final sync = _FlakySyncService()..failSync = true;
      final repository = ExpenseRepository(
        localService: local,
        syncService: sync,
      );

      await repository.insertExpense(
        ExpenseModel(
          amount: 99,
          merchant: 'Cafe',
          category: 'Food',
          createdAt: DateTime(2026, 3, 23, 11, 0),
        ),
      );

      await repository.retryPendingSync();
      expect(repository.syncState.pendingOperations, 1);

      sync.failSync = false;
      await repository.retryPendingSync();

      expect(repository.syncState.pendingOperations, 0);
      expect(repository.syncState.lastSyncError, isNull);
      expect(sync.upserted.length, 1);
      expect(sync.upserted.first.id, isNotNull);
    });
  });
}
