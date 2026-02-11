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
            expandedHeight: 96,
            backgroundColor: Colors.transparent,
            title: const Text('Expense AI'),
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
                _loading ? 'Updating totals...' : 'Track smarter. Spend calmer.',
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
