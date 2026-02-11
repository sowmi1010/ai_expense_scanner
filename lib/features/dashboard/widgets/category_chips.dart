import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/expense_options.dart';
import '../../../core/ui/glass.dart';
import '../../../data/repositories/expense_repository.dart';

class CategoryChips extends StatefulWidget {
  const CategoryChips({super.key});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  final _repo = ExpenseRepository.instance;

  bool _loading = true;
  List<CategoryTotal> _cats = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _repo.changes.addListener(_load);
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_load);
    super.dispose();
  }

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _startOfNextMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final data = await _repo.getCategoryTotals(
        _startOfMonth(),
        _startOfNextMonth(),
      );
      if (!mounted) return;
      setState(() {
        _cats = data;
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
    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final total = _cats.fold<double>(0, (sum, e) => sum + e.total);

    // Limit sections for clarity
    final show = _cats.take(5).toList();

    List<PieChartSectionData> sections() {
      if (total <= 0) {
        return [
          PieChartSectionData(
            value: 1,
            title: 'No data',
            radius: 44,
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            titleStyle: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ];
      }

      // Give each slice a nice themed color variation (based on primary/secondary/tertiary)
      final colors = [
        cs.primary,
        cs.secondary,
        cs.tertiary,
        cs.primaryContainer,
        cs.secondaryContainer,
      ];

      return List.generate(show.length, (i) {
        final v = show[i].total;
        final pct = (v / total) * 100;
        return PieChartSectionData(
          value: v <= 0 ? 0.01 : v,
          title: pct >= 12 ? '${pct.toStringAsFixed(0)}%' : '',
          radius: 52,
          color: colors[i % colors.length],
          titleStyle: TextStyle(
            color: cs.onPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        );
      });
    }

    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                'This month',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.30),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: _loading
                ? const SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: PieChart(
                          PieChartData(
                            sections: sections(),
                            centerSpaceRadius: 34,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              total <= 0
                                  ? 'No spending yet'
                                  : money.format(total),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Top categories',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...show.map((c) {
                              final pct = total <= 0
                                  ? 0
                                  : (c.total / total) * 100;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.category,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${money.format(c.total)}  •  ${pct.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 12),

          // Chips (top categories)
          if (!_loading)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  (show.isEmpty
                          ? ExpenseOptions.categories
                          : show.map((e) => e.category))
                      .map((name) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: cs.primary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        );
                      })
                      .toList(),
            ),
        ],
      ),
    );
  }
}
