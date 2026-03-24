import '../models/expense_model.dart';

abstract class ExpenseSyncService {
  bool get isEnabled;

  Future<void> upsertExpense(ExpenseModel expense);

  Future<void> deleteExpense(int expenseId);
}

class NoopExpenseSyncService implements ExpenseSyncService {
  const NoopExpenseSyncService();

  @override
  bool get isEnabled => false;

  @override
  Future<void> upsertExpense(ExpenseModel expense) async {}

  @override
  Future<void> deleteExpense(int expenseId) async {}
}
