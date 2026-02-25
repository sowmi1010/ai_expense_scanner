import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/ui/app_spacing.dart';
import '../dashboard/dashboard_screen.dart';
import '../monthly/monthly_overview_screen.dart';
import '../scan/scan_landing_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;

  static const _items = [
    _NavItemData(label: 'Home', icon: Icons.grid_view_rounded),
    _NavItemData(label: 'Scan', icon: Icons.document_scanner_rounded),
    _NavItemData(label: 'Monthly', icon: Icons.calendar_month_rounded),
  ];

  final pages = const [
    DashboardScreen(),
    ScanLandingScreen(),
    MonthlyOverviewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ShellBackdrop(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(index),
              child: pages[index],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surface.withValues(alpha: 0.85),
                      cs.surfaceContainerHighest.withValues(alpha: 0.72),
                    ],
                  ),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                      spreadRadius: -10,
                      color: cs.primary.withValues(alpha: 0.22),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(_items.length, (i) {
                    final item = _items[i];
                    return Padding(
                      padding: EdgeInsets.only(right: i == _items.length - 1 ? 0 : 8),
                      child: _NavItem(
                        label: item.label,
                        icon: item.icon,
                        selected: index == i,
                        onTap: () => setState(() => index = i),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;

  const _NavItemData({required this.label, required this.icon});
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.28),
                    cs.tertiary.withValues(alpha: 0.20),
                  ],
                )
              : null,
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: selected
                      ? Padding(
                          key: const ValueKey('label'),
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.surface.withValues(alpha: 0.94),
                  cs.surfaceContainerHighest.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          Positioned(
            top: -95,
            right: -72,
            child: _Orb(
              size: 240,
              color: cs.primary.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 140,
            left: -70,
            child: _Orb(
              size: 190,
              color: cs.tertiary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 110,
            right: -30,
            child: _Orb(
              size: 150,
              color: cs.secondary.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 16,
          ),
        ],
      ),
    );
  }
}
