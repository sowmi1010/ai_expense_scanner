import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/budget_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/ocr_service.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repo.dart';
import '../providers/expense_providers.dart';
import '../providers/service_providers.dart';

final receiptPreviewControllerProvider = Provider<ReceiptPreviewController>((
  ref,
) {
  final repo = ref.watch(expenseRepositoryProvider);
  final ocrService = ref.watch(ocrServiceProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return ReceiptPreviewController(
    repo: repo,
    ocrService: ocrService,
    budgetService: budgetService,
    notificationService: notificationService,
  );
});

class BudgetAlertFeedback {
  final int thresholdPercent;
  final String message;

  const BudgetAlertFeedback({
    required this.thresholdPercent,
    required this.message,
  });
}

class ReceiptPreviewController {
  final ExpenseRepo _repo;
  final OcrService _ocrService;
  final BudgetService _budgetService;
  final NotificationService _notificationService;

  ReceiptPreviewController({
    required ExpenseRepo repo,
    required OcrService ocrService,
    required BudgetService budgetService,
    required NotificationService notificationService,
  }) : _repo = repo,
       _ocrService = ocrService,
       _budgetService = budgetService,
       _notificationService = notificationService;

  Future<OcrScanResult> scanReceiptFromImagePath(String? imagePath) {
    return _ocrService.scanReceiptWithFallback(imagePath);
  }

  Future<BudgetAlertFeedback?> saveExpenseAndCheckBudget(
    ExpenseModel expense,
  ) async {
    await _repo.insertExpense(expense);
    return _checkBudgetAndNotify();
  }

  DateTime _startOfMonth(DateTime now) => DateTime(now.year, now.month, 1);

  DateTime _startOfNextMonth(DateTime now) =>
      DateTime(now.year, now.month + 1, 1);

  Future<BudgetAlertFeedback?> _checkBudgetAndNotify() async {
    final budget = await _budgetService.getMonthlyBudget();
    if (budget <= 0) return null;

    await _budgetService.resetMonthIfNeeded();

    final now = DateTime.now();
    final spent = await _repo.sumByDateRange(
      _startOfMonth(now),
      _startOfNextMonth(now),
    );
    final percent = (spent / budget) * 100;

    if (percent >= 100) {
      final already = await _budgetService.hasTriggered100ThisMonth();
      if (already) return null;

      await _budgetService.markTriggered100ThisMonth();
      final message =
          'Budget exceeded: ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}';

      await _notificationService.showBudgetAlert(
        title: 'Monthly budget exceeded',
        body: message,
      );

      return BudgetAlertFeedback(thresholdPercent: 100, message: message);
    }

    if (percent >= 80) {
      final already = await _budgetService.hasTriggered80ThisMonth();
      if (already) return null;

      await _budgetService.markTriggered80ThisMonth();
      final message =
          'You reached ${percent.toStringAsFixed(0)}%: ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}';

      await _notificationService.showBudgetAlert(
        title: 'Budget warning (80%)',
        body: message,
      );

      return BudgetAlertFeedback(thresholdPercent: 80, message: message);
    }

    return null;
  }
}
