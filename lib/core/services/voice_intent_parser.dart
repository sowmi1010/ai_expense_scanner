import '../constants/expense_options.dart';

enum VoiceIntentType { querySummary, addExpense, unknown }

class VoiceQuery {
  final DateTime start;
  final DateTime end;
  final String? category;

  VoiceQuery({required this.start, required this.end, this.category});
}

class VoiceAddExpense {
  final double amount;
  final String merchant;
  final String category;
  final String paymentMode;
  final DateTime createdAt;

  VoiceAddExpense({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.paymentMode,
    required this.createdAt,
  });
}

class VoiceIntent {
  final VoiceIntentType type;
  final VoiceQuery? query;
  final VoiceAddExpense? addExpense;

  const VoiceIntent._({
    required this.type,
    this.query,
    this.addExpense,
  });

  factory VoiceIntent.query(VoiceQuery query) {
    return VoiceIntent._(type: VoiceIntentType.querySummary, query: query);
  }

  factory VoiceIntent.add(VoiceAddExpense addExpense) {
    return VoiceIntent._(
      type: VoiceIntentType.addExpense,
      addExpense: addExpense,
    );
  }

  factory VoiceIntent.unknown() {
    return const VoiceIntent._(type: VoiceIntentType.unknown);
  }
}

class VoiceIntentParser {
  static VoiceIntent parse(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty) return VoiceIntent.unknown();

    final amount = _extractAmount(normalized);
    final addVerb = RegExp(
      r'\b(add|spent|spend|paid|pay|recharge|transfer|sent|bought|purchase)\b',
    ).hasMatch(normalized);
    final paymentHint = RegExp(
      r'\b(gpay|google pay|upi|phonepe|paytm|neft|imps|rtgs|bank transfer)\b',
    ).hasMatch(normalized);

    if (amount != null && (addVerb || paymentHint)) {
      final createdAt = _extractSingleDate(normalized);
      final category = ExpenseOptions.detectCategoryFromText(normalized);
      final paymentMode = ExpenseOptions.detectPaymentModeFromText(normalized);
      final merchant = _extractMerchant(normalized);

      return VoiceIntent.add(
        VoiceAddExpense(
          amount: amount,
          merchant: merchant,
          category: category,
          paymentMode: paymentMode,
          createdAt: createdAt,
        ),
      );
    }

    if (_looksLikeQuery(normalized)) {
      return VoiceIntent.query(_parseQuery(normalized));
    }

    // Fall back to query mode if intent is ambiguous.
    return VoiceIntent.query(_parseQuery(normalized));
  }

  static bool _looksLikeQuery(String text) {
    return RegExp(
      r'\b(how much|total|spent|spending|show|summary|report)\b',
    ).hasMatch(text);
  }

  static VoiceQuery _parseQuery(String text) {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    if (text.contains('today')) {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    } else if (text.contains('yesterday')) {
      start = DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 1),
      );
      end = start.add(const Duration(days: 1));
    } else if (text.contains('last week')) {
      end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      start = end.subtract(const Duration(days: 7));
    } else if (text.contains('this month') || text.contains('month')) {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
    } else if (text.contains('last month')) {
      final firstThisMonth = DateTime(now.year, now.month, 1);
      start = DateTime(firstThisMonth.year, firstThisMonth.month - 1, 1);
      end = firstThisMonth;
    } else {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    }

    final category = _extractQueryCategory(text);

    return VoiceQuery(start: start, end: end, category: category);
  }

  static String? _extractQueryCategory(String text) {
    final explicitMap = <String, String>{
      'food': 'Food',
      'grocer': 'Groceries',
      'travel': 'Travel',
      'shopping': 'Shopping',
      'bill': 'Bills',
      'recharge': 'Recharge',
      'saving': 'Savings',
      'transfer': 'Bank Transfer',
      'bank': 'Bank Transfer',
    };

    for (final entry in explicitMap.entries) {
      if (text.contains(entry.key)) return entry.value;
    }

    // Return null when no category keyword is found so query can include all.
    return null;
  }

  static double? _extractAmount(String text) {
    final match = RegExp(
      r'(?:rs\.?|inr|rupees?)?\s*(\d{1,7}(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(text.replaceAll(',', ''));

    if (match == null) return null;
    final value = double.tryParse(match.group(1) ?? '');
    if (value == null || value <= 0) return null;
    return value;
  }

  static DateTime _extractSingleDate(String text) {
    final now = DateTime.now();

    if (text.contains('yesterday')) {
      final y = now.subtract(const Duration(days: 1));
      return DateTime(y.year, y.month, y.day, now.hour, now.minute);
    }

    if (text.contains('today')) {
      return now;
    }

    final dmy = RegExp(r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2,4})');
    final ymd = RegExp(r'(\d{4})[\/\.\-](\d{1,2})[\/\.\-](\d{1,2})');

    final m1 = dmy.firstMatch(text);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!);
      final month = int.tryParse(m1.group(2)!);
      var year = int.tryParse(m1.group(3)!);
      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        return DateTime(year, month, day, now.hour, now.minute);
      }
    }

    final m2 = ymd.firstMatch(text);
    if (m2 != null) {
      final year = int.tryParse(m2.group(1)!);
      final month = int.tryParse(m2.group(2)!);
      final day = int.tryParse(m2.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day, now.hour, now.minute);
      }
    }

    return now;
  }

  static String _extractMerchant(String text) {
    final patterns = <RegExp>[
      RegExp(r'\bat\s+([a-z][a-z0-9 &\.\-]{2,40})'),
      RegExp(r'\bto\s+([a-z][a-z0-9 &\.\-]{2,40})'),
      RegExp(r'\bfor\s+([a-z][a-z0-9 &\.\-]{2,40})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final captured = match?.group(1)?.trim();
      if (captured == null || captured.isEmpty) continue;

      final cleaned = captured
          .replaceAll(
            RegExp(r'\b(today|yesterday|month|week|cash|gpay|upi)\b'),
            '',
          )
          .trim();
      if (cleaned.isEmpty) continue;
      return _titleCase(cleaned);
    }

    return 'Voice Entry';
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          final first = word.substring(0, 1).toUpperCase();
          final rest = word.length > 1 ? word.substring(1).toLowerCase() : '';
          return '$first$rest';
        })
        .join(' ');
  }
}
