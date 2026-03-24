import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/ui/glass.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../state/providers/expense_providers.dart';

class SpendLineCard extends ConsumerWidget {
  const SpendLineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pointsAsync = ref.watch(weeklySpendTrendProvider(7));
    final points = pointsAsync.valueOrNull ?? const <DailyTotal>[];
    final loading = pointsAsync.isLoading;
    final hasError = pointsAsync.hasError;

    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 0,
    );

    final maxY = points.isEmpty
        ? 0.0
        : points.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxY <= 0 ? 100.0 : maxY * 1.2;

    final chartCount = points.isEmpty ? 7 : points.length;
    final maxX = (chartCount - 1).toDouble();

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].total));
    }

    final totalSpend = points.fold<double>(0, (sum, e) => sum + e.total);
    final avgSpend = points.isEmpty ? 0 : totalSpend / points.length;

    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.dashboardSpendTrendTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                points.isEmpty
                    ? 'No data yet'
                    : 'Avg ${money.format(avgSpend)}',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 182,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surfaceContainerHighest.withValues(alpha: 0.30),
                  cs.surface.withValues(alpha: 0.22),
                ],
              ),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 14, 16, 8),
            child: loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : hasError
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, color: cs.error),
                        const SizedBox(height: 8),
                        Text(
                          'Could not load trend data',
                          style: TextStyle(
                            color: cs.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () =>
                              ref.invalidate(weeklySpendTrendProvider(7)),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX,
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
                            reservedSize: 52,
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
                              if (i < 0 || i >= points.length) {
                                return const SizedBox.shrink();
                              }
                              final label = DateFormat(
                                'E',
                              ).format(points[i].day);
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
                            return touchedSpots.map((spot) {
                              final idx = spot.x.toInt();
                              final day = (idx >= 0 && idx < points.length)
                                  ? DateFormat('dd MMM').format(points[idx].day)
                                  : '';
                              return LineTooltipItem(
                                '$day\n${money.format(spot.y)}',
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
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.tertiary],
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                cs.primary.withValues(alpha: 0.24),
                                cs.primary.withValues(alpha: 0.04),
                              ],
                            ),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
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
