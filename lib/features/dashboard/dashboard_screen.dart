import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../data/repositories/expense_repository.dart';
import '../../routes/app_routes.dart';
import 'widgets/category_chips.dart';
import 'widgets/insight_card.dart';
import 'widgets/quick_action.dart';
import 'widgets/spend_line_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = ExpenseRepository.instance;

  bool _loading = true;
  double _todayTotal = 0;
  int _todayCount = 0;
  double _monthTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _repo.changes.addListener(_loadStats);
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_loadStats);
    super.dispose();
  }

  String _money(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _startOfTomorrow() => _startOfToday().add(const Duration(days: 1));

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _startOfNextMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final todayStart = _startOfToday();
      final tomorrowStart = _startOfTomorrow();
      final monthStart = _startOfMonth();
      final nextMonthStart = _startOfNextMonth();

      final todayTotal = await _repo.sumByDateRange(todayStart, tomorrowStart);
      final todayCount = await _repo.countByDateRange(todayStart, tomorrowStart);
      final monthTotal = await _repo.sumByDateRange(monthStart, nextMonthStart);

      if (!mounted) return;
      setState(() {
        _todayTotal = todayTotal;
        _todayCount = todayCount;
        _monthTotal = monthTotal;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 108,
            backgroundColor: Colors.transparent,
            title: const Text('Expense Radar'),
            actions: [
              IconButton(
                onPressed: _loadStats,
                icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.voice);
                },
                icon: Icon(Icons.keyboard_voice_rounded, color: cs.onSurface),
                tooltip: 'Voice',
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
              child: Text(
                _loading
                    ? 'Updating today and monthly totals...'
                    : 'Smarter tracking for calmer spending.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HeroSummary(
                  loading: _loading,
                  todayTotal: _money(_todayTotal),
                  todayCount: _todayCount,
                  monthTotal: _money(_monthTotal),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: InsightCard(
                        title: 'Today',
                        value: _money(_todayTotal),
                        subtitle: '$_todayCount transactions',
                        icon: Icons.today_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InsightCard(
                        title: 'This month',
                        value: _money(_monthTotal),
                        subtitle: 'Budget: Rs 0',
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const SpendLineCard(),
                const SizedBox(height: AppSpacing.md),
                const CategoryChips(),
                const SizedBox(height: AppSpacing.md),
                Glass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick actions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.receiptPreview,
                                );
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
                                Navigator.pushNamed(context, AppRoutes.camera);
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
                                Navigator.pushNamed(context, AppRoutes.scan);
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
                                Navigator.pushNamed(context, AppRoutes.voice);
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
                      'Today at a glance',
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
