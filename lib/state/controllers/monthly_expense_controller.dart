import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repo.dart';
import '../providers/expense_providers.dart';

final monthlyExpenseControllerProvider = Provider<MonthlyExpenseController>((
  ref,
) {
  final repo = ref.watch(expenseRepositoryProvider);
  return MonthlyExpenseController(repo: repo);
});

class MonthlyExpenseController {
  final ExpenseRepo _repo;

  MonthlyExpenseController({required ExpenseRepo repo}) : _repo = repo;

  Future<void> updateExpense(ExpenseModel expense) async {
    await _repo.updateExpense(expense);
  }

  Future<void> deleteExpense(int id) async {
    await _repo.deleteExpense(id);
  }
}
