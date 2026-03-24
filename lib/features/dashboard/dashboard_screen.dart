import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../routes/app_routes.dart';
import '../../state/controllers/dashboard_controller.dart';
import 'widgets/category_chips.dart';
import 'widgets/insight_card.dart';
import 'widgets/quick_action.dart';
import 'widgets/spend_line_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(dashboardControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 108,
            backgroundColor: Colors.transparent,
            title: const Text(AppStrings.dashboardTitle),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: controller.isRefreshing,
                builder: (context, refreshing, _) {
                  return IconButton(
                    onPressed: refreshing
                        ? null
                        : () {
                            unawaited(controller.refreshDashboardData());
                          },
                    icon: refreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh_rounded, color: cs.onSurface),
                    tooltip: AppStrings.dashboardRefreshTooltip,
                  );
                },
              ),
              IconButton(
                onPressed: () {
                  AppRoutes.toVoice(context);
                },
                icon: Icon(Icons.keyboard_voice_rounded, color: cs.onSurface),
                tooltip: AppStrings.dashboardVoiceTooltip,
              ),
              const SizedBox(width: 6),
            ],
            flexibleSpace: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                56,
                AppSpacing.md,
                0,
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final subtitle = ref.watch(
                    dashboardViewModelProvider.select(
                      (vm) => vm.flexibleSubtitle,
                    ),
                  );
                  final statsError = ref.watch(
                    dashboardViewModelProvider.select((vm) => vm.errorMessage),
                  );

                  return Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statsError != null
                          ? cs.error
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _DashboardTopSummary(),
                const SizedBox(height: AppSpacing.md),
                const RepaintBoundary(child: SpendLineCard()),
                const SizedBox(height: AppSpacing.md),
                const RepaintBoundary(child: CategoryChips()),
                const SizedBox(height: AppSpacing.md),
                Glass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.dashboardQuickActions,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: QuickAction(
                              icon: Icons.add_rounded,
                              title: 'Add expense',
                              subtitle: 'No bill manual',
                              onTap: () {
                                AppRoutes.toReceiptPreview(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickAction(
                              icon: Icons.document_scanner_rounded,
                              title: 'Scan receipt',
                              subtitle: 'Camera OCR',
                              onTap: () {
                                AppRoutes.toCamera(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: QuickAction(
                              icon: Icons.photo_library_rounded,
                              title: 'Gallery bill',
                              subtitle: 'Import image',
                              onTap: () {
                                AppRoutes.toScan(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickAction(
                              icon: Icons.keyboard_voice_rounded,
                              title: 'Voice',
                              subtitle: 'Speak and save',
                              onTap: () {
                                AppRoutes.toVoice(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTopSummary extends ConsumerWidget {
  const _DashboardTopSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(dashboardViewModelProvider);
    final controller = ref.read(dashboardControllerProvider);

    return Column(
      children: [
        if (vm.errorMessage != null) ...[
          _DashboardErrorCard(
            message: vm.errorMessage!,
            onRetry: controller.refreshDashboardData,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _HeroSummary(
          loading: vm.loading,
          todayTotal: vm.todayTotal,
          todayCount: vm.todayCount,
          monthTotal: vm.monthTotal,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: InsightCard(
                title: AppStrings.dashboardInsightTitleToday,
                value: vm.todayTotal,
                subtitle: '${vm.todayCount} transactions',
                icon: Icons.today_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InsightCard(
                title: AppStrings.dashboardInsightTitleMonth,
                value: vm.monthTotal,
                subtitle: 'Budget: Rs 0',
                icon: Icons.calendar_month_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final bool loading;
  final String todayTotal;
  final int todayCount;
  final String monthTotal;

  const _HeroSummary({
    required this.loading,
    required this.todayTotal,
    required this.todayCount,
    required this.monthTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Glass(
      emphasize: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dashboardTodayAtAGlance,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loading
                          ? 'Calculating fresh insights...'
                          : 'You have $todayCount expenses logged today.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: 0.30),
                      cs.tertiary.withValues(alpha: 0.20),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: cs.primary,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  label: 'Today spend',
                  value: todayTotal,
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  label: 'This month',
                  value: monthTotal,
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface.withValues(alpha: 0.58),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
