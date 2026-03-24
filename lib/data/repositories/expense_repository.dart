import 'dart:async';
import 'dart:collection';

import '../models/expense_model.dart';
import '../services/expense_local_service.dart';
import '../services/expense_sync_service.dart';
import '../../core/logging/app_logger.dart';
import 'expense_repo.dart';

export 'expense_repo.dart'
    show CategoryTotal, DailyTotal, ExpenseRepo, OfflineSyncState;

enum _SyncOperationType { upsert, delete }

class _PendingSyncOperation {
  final _SyncOperationType type;
  final ExpenseModel? expense;
  final int? expenseId;

  const _PendingSyncOperation.upsert(this.expense)
    : type = _SyncOperationType.upsert,
      expenseId = null;

  const _PendingSyncOperation.delete(this.expenseId)
    : type = _SyncOperationType.delete,
      expense = null;

  String get dedupeKey {
    switch (type) {
      case _SyncOperationType.upsert:
        return 'upsert:${expense?.id ?? 'unknown'}';
      case _SyncOperationType.delete:
        return 'delete:${expenseId ?? 'unknown'}';
    }
  }
}

class ExpenseRepository extends ExpenseRepo {
  final ExpenseLocalService _localService;
  final ExpenseSyncService _syncService;

  static const int _maxCacheEntries = 120;

  final LinkedHashMap<String, double> _sumByRangeCache = LinkedHashMap();
  final LinkedHashMap<String, int> _countByRangeCache = LinkedHashMap();
  final LinkedHashMap<String, List<ExpenseModel>> _expensesInRangeCache =
      LinkedHashMap();
  final LinkedHashMap<String, List<DailyTotal>> _dailyTotalsCache =
      LinkedHashMap();
  final LinkedHashMap<String, List<CategoryTotal>> _categoryTotalsCache =
      LinkedHashMap();
  final LinkedHashMap<String, double> _sumByDateCategoryCache = LinkedHashMap();

  final List<_PendingSyncOperation> _pendingSyncOperations = [];
  bool _syncInProgress = false;
  DateTime? _lastSyncAttemptAt;
  String? _lastSyncError;

  ExpenseRepository({
    required ExpenseLocalService localService,
    ExpenseSyncService? syncService,
  }) : _localService = localService,
       _syncService = syncService ?? const NoopExpenseSyncService();

  @override
  OfflineSyncState get syncState {
    if (!_syncService.isEnabled) return OfflineSyncState.disabled;

    return OfflineSyncState(
      syncEnabled: true,
      syncInProgress: _syncInProgress,
      pendingOperations: _pendingSyncOperations.length,
      lastSyncAttemptAt: _lastSyncAttemptAt,
      lastSyncError: _lastSyncError,
    );
  }

  @override
  Future<void> retryPendingSync() => _flushPendingSync();

  String _rangeKey(DateTime start, DateTime end) =>
      '${start.toIso8601String()}|${end.toIso8601String()}';

  void _cachePut<K, V>(LinkedHashMap<K, V> cache, K key, V value) {
    if (!cache.containsKey(key) && cache.length >= _maxCacheEntries) {
      cache.remove(cache.keys.first);
    }
    cache[key] = value;
  }

  void _clearReadCaches() {
    _sumByRangeCache.clear();
    _countByRangeCache.clear();
    _expensesInRangeCache.clear();
    _dailyTotalsCache.clear();
    _categoryTotalsCache.clear();
    _sumByDateCategoryCache.clear();
  }

  void _notifyDataChanged() {
    _clearReadCaches();
    notifyListeners();
  }

  ExpenseModel _withId(ExpenseModel expense, int id) {
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

  void _enqueueSyncOperation(_PendingSyncOperation operation) {
    if (!_syncService.isEnabled) return;

    _pendingSyncOperations.removeWhere(
      (item) =>
          item.dedupeKey == operation.dedupeKey ||
          (item.expense?.id != null &&
              operation.expenseId != null &&
              item.expense!.id == operation.expenseId),
    );
    _pendingSyncOperations.add(operation);
    AppLogger.info(
      'Queued offline sync operation (${operation.type.name}). Pending: ${_pendingSyncOperations.length}',
    );
    notifyListeners();

    unawaited(_flushPendingSync());
  }

  Future<void> _applySyncOperation(_PendingSyncOperation operation) async {
    switch (operation.type) {
      case _SyncOperationType.upsert:
        final expense = operation.expense;
        if (expense == null) return;
        await _syncService.upsertExpense(expense);
        return;
      case _SyncOperationType.delete:
        final expenseId = operation.expenseId;
        if (expenseId == null) return;
        await _syncService.deleteExpense(expenseId);
        return;
    }
  }

  Future<void> _flushPendingSync() async {
    if (!_syncService.isEnabled ||
        _syncInProgress ||
        _pendingSyncOperations.isEmpty) {
      return;
    }

    _syncInProgress = true;
    notifyListeners();

    try {
      while (_pendingSyncOperations.isNotEmpty) {
        final operation = _pendingSyncOperations.first;
        _lastSyncAttemptAt = DateTime.now();

        try {
          await _applySyncOperation(operation);
          _pendingSyncOperations.removeAt(0);
          _lastSyncError = null;
          AppLogger.debug(
            'Synced pending operation (${operation.type.name}). Remaining: ${_pendingSyncOperations.length}',
          );
        } catch (e) {
          _lastSyncError = e.toString();
          AppLogger.warning(
            'Sync failed. Keeping operation queued for retry.',
            error: e,
          );
          break;
        }
      }
    } finally {
      _syncInProgress = false;
      notifyListeners();
    }
  }

  @override
  Future<int> insertExpense(ExpenseModel expense) async {
    expense.validateOrThrow();

    final id = await _localService.insertExpense(expense);
    final persisted = _withId(expense, id);
    _enqueueSyncOperation(_PendingSyncOperation.upsert(persisted));
    _notifyDataChanged();
    return id;
  }

  @override
  Future<int> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) return 0;
    expense.validateOrThrow();

    final updated = await _localService.updateExpense(expense);
    if (updated > 0) {
      _enqueueSyncOperation(_PendingSyncOperation.upsert(expense));
      _notifyDataChanged();
    }
    return updated;
  }

  @override
  Future<int> deleteExpense(int id) async {
    final deleted = await _localService.deleteExpense(id);
    if (deleted > 0) {
      _enqueueSyncOperation(_PendingSyncOperation.delete(id));
      _notifyDataChanged();
    }
    return deleted;
  }

  @override
  Future<double> sumByDateRange(DateTime start, DateTime end) async {
    final key = _rangeKey(start, end);
    final cached = _sumByRangeCache[key];
    if (cached != null) return cached;

    final total = await _localService.sumByDateRange(start, end);
    _cachePut(_sumByRangeCache, key, total);
    return total;
  }

  @override
  Future<int> countByDateRange(DateTime start, DateTime end) async {
    final key = _rangeKey(start, end);
    final cached = _countByRangeCache[key];
    if (cached != null) return cached;

    final count = await _localService.countByDateRange(start, end);
    _cachePut(_countByRangeCache, key, count);
    return count;
  }

  @override
  Future<List<ExpenseModel>> getExpensesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final key = _rangeKey(start, end);
    final cached = _expensesInRangeCache[key];
    if (cached != null) return cached;

    final items = await _localService.getExpensesInRange(start, end);
    _cachePut(_expensesInRangeCache, key, items);
    return items;
  }

  @override
  Future<List<DailyTotal>> getDailyTotals({int days = 7}) async {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    final key = '$dayKey|$days';
    final cached = _dailyTotalsCache[key];
    if (cached != null) return cached;

    final items = await _localService.getDailyTotals(days: days);
    _cachePut(_dailyTotalsCache, key, items);
    return items;
  }

  @override
  Future<List<CategoryTotal>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final key = _rangeKey(start, end);
    final cached = _categoryTotalsCache[key];
    if (cached != null) return cached;

    final items = await _localService.getCategoryTotals(start, end);
    _cachePut(_categoryTotalsCache, key, items);
    return items;
  }

  @override
  Future<double> sumByDateAndCategory(
    DateTime start,
    DateTime end,
    String? category,
  ) async {
    final key = '${_rangeKey(start, end)}|${category ?? '_all'}';
    final cached = _sumByDateCategoryCache[key];
    if (cached != null) return cached;

    final total = await _localService.sumByDateAndCategory(
      start,
      end,
      category,
    );
    _cachePut(_sumByDateCategoryCache, key, total);
    return total;
  }
}
