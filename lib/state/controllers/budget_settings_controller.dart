import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/budget_service.dart';
import '../providers/service_providers.dart';

final budgetSettingsControllerProvider = Provider<BudgetSettingsController>((
  ref,
) {
  final budgetService = ref.watch(budgetServiceProvider);
  return BudgetSettingsController(budgetService: budgetService);
});

class BudgetSettingsController {
  final BudgetService _budgetService;

  BudgetSettingsController({required BudgetService budgetService})
    : _budgetService = budgetService;

  Future<double> getMonthlyBudget() => _budgetService.getMonthlyBudget();

  Future<void> setMonthlyBudget(double value) =>
      _budgetService.setMonthlyBudget(value);
}
