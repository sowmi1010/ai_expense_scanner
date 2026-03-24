import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../providers/expense_providers.dart';

final dashboardControllerProvider = Provider<DashboardController>((ref) {
  final controller = DashboardController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

final dashboardViewModelProvider = Provider<DashboardViewModel>((ref) {
  final controller = ref.watch(dashboardControllerProvider);
  final statsAsync = ref.watch(dashboardStatsProvider);
  return controller.buildViewModel(statsAsync);
});

class DashboardViewModel {
  final bool loading;
  final String? errorMessage;
  final String flexibleSubtitle;
  final String todayTotal;
  final int todayCount;
  final String monthTotal;

  const DashboardViewModel({
    required this.loading,
    required this.errorMessage,
    required this.flexibleSubtitle,
    required this.todayTotal,
    required this.todayCount,
    required this.monthTotal,
  });
}

class DashboardController {
  final Ref _ref;
  final ValueNotifier<bool> isRefreshing = ValueNotifier(false);

  DashboardController(this._ref);

  String _money(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Future<void> refreshDashboardData() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(weeklySpendTrendProvider(7));
    _ref.invalidate(currentMonthCategoryTotalsProvider);

    // Keep a brief refreshing state to avoid rapid repeated invalidation spam.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    isRefreshing.value = false;
  }

  void dispose() {
    isRefreshing.dispose();
  }

  DashboardViewModel buildViewModel(AsyncValue<DashboardStats> statsAsync) {
    final stats = statsAsync.valueOrNull ?? DashboardStats.empty;
    final loading = statsAsync.isLoading;
    final errorMessage = statsAsync.hasError
        ? AppStrings.dashboardStatsError
        : null;

    return DashboardViewModel(
      loading: loading,
      errorMessage: errorMessage,
      flexibleSubtitle: loading
          ? AppStrings.dashboardLoadingSubtitle
          : (errorMessage ?? AppStrings.dashboardSubtitle),
      todayTotal: _money(stats.todayTotal),
      todayCount: stats.todayCount,
      monthTotal: _money(stats.monthTotal),
    );
  }
}
