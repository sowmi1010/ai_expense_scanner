import 'package:flutter/material.dart';

class AppTheme {
  static const Color _lightSeed = Color(0xFF0C8A87);
  static const Color _darkSeed = Color(0xFF26C2B7);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _lightSeed,
      brightness: Brightness.light,
    ).copyWith(
      secondary: const Color(0xFFF36D4E),
      tertiary: const Color(0xFF4F6CFF),
      surface: const Color(0xFFF9FBFF),
      surfaceContainerHighest: const Color(0xFFEAF0F8),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF3F7FC),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: _appBarTheme(base.textTheme, scheme),
      cardTheme: _cardTheme(scheme),
      inputDecorationTheme: _inputDecorationTheme(scheme),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(scheme),
      chipTheme: _chipTheme(scheme),
      tabBarTheme: _tabBarTheme(scheme),
      snackBarTheme: _snackBarTheme(scheme),
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _darkSeed,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFFFF8A5C),
      tertiary: const Color(0xFF8B9AFF),
      surface: const Color(0xFF10131D),
      surfaceContainerHighest: const Color(0xFF1A2130),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF090D16),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: _appBarTheme(base.textTheme, scheme),
      cardTheme: _cardTheme(scheme),
      inputDecorationTheme: _inputDecorationTheme(scheme),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(scheme),
      chipTheme: _chipTheme(scheme),
      tabBarTheme: _tabBarTheme(scheme),
      snackBarTheme: _snackBarTheme(scheme),
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final themed = base.apply(fontFamily: 'Poppins');
    return themed.copyWith(
      headlineSmall: themed.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
      titleLarge: themed.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleMedium: themed.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      bodyLarge: themed.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: themed.bodyMedium?.copyWith(height: 1.35),
      labelLarge: themed.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }

  static AppBarTheme _appBarTheme(TextTheme textTheme, ColorScheme scheme) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: scheme.onSurface,
      ),
    );
  }

  static CardThemeData _cardTheme(ColorScheme scheme) {
    return CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface.withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.45),
      ),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme scheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static ChipThemeData _chipTheme(ColorScheme scheme) {
    return ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      selectedColor: scheme.primary.withValues(alpha: 0.2),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      showCheckmark: false,
    );
  }

  static TabBarThemeData _tabBarTheme(ColorScheme scheme) {
    return TabBarThemeData(
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.primary.withValues(alpha: 0.14),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  static SnackBarThemeData _snackBarTheme(ColorScheme scheme) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
