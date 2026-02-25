import 'dart:ui';
import 'package:flutter/material.dart';

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius radius;
  final bool emphasize;
  final Gradient? gradient;

  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = const BorderRadius.all(Radius.circular(24)),
    this.emphasize = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cs = Theme.of(context).colorScheme;
    final baseAlpha = brightness == Brightness.dark ? 0.45 : 0.64;
    final accentAlpha = brightness == Brightness.dark ? 0.12 : 0.15;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient:
                gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.surface.withValues(alpha: baseAlpha),
                    cs.surface.withValues(alpha: baseAlpha - 0.08),
                    cs.primary.withValues(alpha: emphasize ? accentAlpha : 0.08),
                  ],
                ),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: emphasize ? 0.55 : 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: emphasize ? 0.16 : 0.07),
                blurRadius: emphasize ? 30 : 18,
                offset: const Offset(0, 10),
                spreadRadius: emphasize ? -4 : -6,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
