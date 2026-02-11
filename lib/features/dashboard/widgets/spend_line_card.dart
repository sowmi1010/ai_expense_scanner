import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/glass.dart';
import '../../../data/repositories/expense_repository.dart';

class SpendLineCard extends StatefulWidget {
  const SpendLineCard({super.key});

  @override
  State<SpendLineCard> createState() => _SpendLineCardState();
}

class _SpendLineCardState extends State<SpendLineCard> {
  final _repo = ExpenseRepository.instance;

  bool _loading = true;
  List<DailyTotal> _points = const [];

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

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final data = await _repo.getDailyTotals(days: 7);
      if (!mounted) return;
      setState(() {
        _points = data;
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

    final maxY = _points.isEmpty
        ? 0.0
        : _points.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    final safeMaxY = (maxY <= 0) ? 100.0 : (maxY * 1.2);

    final spots = <FlSpot>[];
    for (int i = 0; i < _points.length; i++) {
      spots.add(FlSpot(i.toDouble(), _points[i].total));
    }

    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Spending trend',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                'Last 7 days',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 14, 16, 8),
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: safeMaxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: safeMaxY / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            interval: safeMaxY / 4,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  money.format(value),
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= _points.length) {
                                return const SizedBox.shrink();
                              }
                              final d = _points[i].day;
                              final label = DateFormat(
                                'E',
                              ).format(d); // Mon/Tue
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 12,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((s) {
                              final idx = s.x.toInt();
                              final day = (idx >= 0 && idx < _points.length)
                                  ? DateFormat(
                                      'dd MMM',
                                    ).format(_points[idx].day)
                                  : '';
                              return LineTooltipItem(
                                '$day\n${money.format(s.y)}',
                                TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 3,
                          color: cs.primary,
                          belowBarData: BarAreaData(
                            show: true,
                            color: cs.primary.withValues(alpha: 0.12),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, _, _, _) =>
                                FlDotCirclePainter(
                                  radius: 3.5,
                                  color: cs.primary,
                                  strokeWidth: 2,
                                  strokeColor: cs.surface,
                                ),
                          ),
                          spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
