import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../constants/expense_options.dart';

class ParsedReceipt {
  final String rawText;
  final double? totalAmount;
  final DateTime? date;
  final String? merchant;
  final String? category;

  ParsedReceipt({
    required this.rawText,
    this.totalAmount,
    this.date,
    this.merchant,
    this.category,
  });
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static final RegExp _currencyAmountRegex = RegExp(
    r'(?:\u20B9|rs\.?|inr)\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _plainAmountRegex = RegExp(
    r'\b([0-9]{1,7}(?:\.[0-9]{1,2})?)\b',
    caseSensitive: false,
  );

  static final RegExp _merchantNoiseRegex = RegExp(
    r'(invoice|bill\s*no|gstin|hsn|statecode|transaction\s*id|google\s*transaction|utr|ref\s*no|phone\s*no|mobile\s*no|consumer\s*no|cons\s*no|account|pin|qty|rate|tax|cgst|sgst|igst|docc|working\s*hours)',
    caseSensitive: false,
  );

  static final RegExp _merchantPositiveRegex = RegExp(
    r'(airtel|jio|vodafone|bharat\s*gas|bharatgas|indane|hp\s*gas|tnpdcl|electricity|power|postpaid|broadband|agency|jewellers?|jewelry|store|mart|restaurant|hotel|supermarket)',
    caseSensitive: false,
  );

  static final RegExp _strongAmountKeywordsRegex = RegExp(
    r'(grand\s*total|net\s*total|total\s*amount|total\s*payable|amount\s*due|bill\s*amount|paid|debited|payment\s*successful|transaction\s*successful|transaction\s*complete|net\s*amount)',
    caseSensitive: false,
  );

  static final RegExp _mediumAmountKeywordsRegex = RegExp(
    r'(total|amount|payable|due|balance|receipt|invoice|bill)',
    caseSensitive: false,
  );

  static final RegExp _noiseAmountKeywordsRegex = RegExp(
    r'(invoice\s*no|bill\s*no|transaction\s*id|google\s*transaction|utr|ref\s*no|consumer\s*no|cons\s*no|phone\s*no|mobile\s*no|gstin|hsn|account|pin|statecode|docc|code)',
    caseSensitive: false,
  );

  static final RegExp _taxKeywordsRegex = RegExp(
    r'(cgst|sgst|igst|gst|tax|cess|discount|qty|rate|unit|base\s*rate)',
    caseSensitive: false,
  );

  static final RegExp _dateHintRegex = RegExp(
    r'(\d{1,2}[\/\.\-]\d{1,2}[\/\.\-]\d{2,4}|\bjan\b|\bfeb\b|\bmar\b|\bapr\b|\bmay\b|\bjun\b|\bjul\b|\baug\b|\bsep\b|\boct\b|\bnov\b|\bdec\b)',
    caseSensitive: false,
  );

  Future<ParsedReceipt> scanReceiptFromImagePath(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(inputImage);

    final rawText = result.text.trim();
    final normalized = _normalizeText(rawText);
    final lines = _splitLines(normalized);

    final merchant = _guessMerchant(result, lines);
    final total = _extractTotalAmount(lines);
    final date = _extractDate(lines);
    final category = ExpenseOptions.detectCategoryFromText(
      '$normalized\n${merchant ?? ''}',
    );

    return ParsedReceipt(
      rawText: rawText,
      totalAmount: total,
      date: date,
      merchant: merchant,
      category: category,
    );
  }

  String _normalizeText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('Ã¢â€šÂ¹', '\u20B9')
        .replaceAll('â‚¹', '\u20B9')
        .replaceAll('rs.', 'rs ')
        .replaceAll('inr.', 'inr ')
        .trim();
  }

  List<String> _splitLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String? _guessMerchant(RecognizedText recognizedText, List<String> fallbackLines) {
    final orderedLines = <String>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final value = line.text.trim();
        if (value.isNotEmpty) orderedLines.add(value);
      }
      if (orderedLines.length > 30) break;
    }

    if (orderedLines.isEmpty) {
      orderedLines.addAll(fallbackLines.take(30));
    }

    for (final line in orderedLines) {
      final paidToMatch = RegExp(
        r'paid\s*to\s*[:\-]?\s*(.+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (paidToMatch != null) {
        final candidate = _cleanMerchantLine(paidToMatch.group(1)!);
        if (_isLikelyMerchant(candidate)) return candidate;
      }

      final merchantLabelMatch = RegExp(
        r'(?:merchant|biller|operator|provider)\s*[:\-]\s*(.+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (merchantLabelMatch != null) {
        final candidate = _cleanMerchantLine(merchantLabelMatch.group(1)!);
        if (_isLikelyMerchant(candidate)) return candidate;
      }
    }

    String? best;
    var bestScore = -999;

    for (var i = 0; i < orderedLines.length; i++) {
      final raw = orderedLines[i];
      final cleaned = _cleanMerchantLine(raw);
      if (!_isLikelyMerchant(cleaned)) continue;

      final lower = cleaned.toLowerCase();
      final digits = RegExp(r'\d').allMatches(cleaned).length;
      final letters = RegExp(r'[A-Za-z]').allMatches(cleaned).length;

      var score = 0;
      if (i < 4) score += 3;
      if (i >= 4 && i < 10) score += 1;
      if (letters > 2) score += 2;
      if (digits == 0) score += 2;
      if (_merchantPositiveRegex.hasMatch(lower)) score += 4;
      if (_merchantNoiseRegex.hasMatch(lower)) score -= 8;
      if (digits > letters) score -= 4;
      if (cleaned.split(RegExp(r'\s+')).length >= 2) score += 1;

      if (score > bestScore) {
        bestScore = score;
        best = cleaned;
      }
    }

    if (best != null && bestScore > 0) return best;
    return orderedLines.isNotEmpty ? _cleanMerchantLine(orderedLines.first) : null;
  }

  String _cleanMerchantLine(String line) {
    return line.replaceAll(RegExp(r'[^A-Za-z0-9 &\.\-]'), ' ').replaceAll(
      RegExp(r'\s+'),
      ' ',
    ).trim();
  }

  bool _isLikelyMerchant(String line) {
    if (line.length < 3) return false;
    if (RegExp(r'^\d+$').hasMatch(line)) return false;
    return RegExp(r'[A-Za-z]').hasMatch(line);
  }

  double? _extractTotalAmount(List<String> lines) {
    final candidates = <_AmountCandidate>[];

    for (final line in lines) {
      candidates.addAll(_extractCandidatesFromLine(line));
    }
    candidates.addAll(_extractDerivedTotalCandidates(lines));

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.value.compareTo(a.value);
    });

    final best = candidates.first;
    if (best.score >= 3) return best.value;

    final currencyMatches = candidates
        .where((c) => c.hasCurrency)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (currencyMatches.isNotEmpty) return currencyMatches.first.value;

    final nonNoisy = candidates
        .where((c) => c.score > -3)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (nonNoisy.isNotEmpty) return nonNoisy.first.value;

    candidates.sort((a, b) => b.value.compareTo(a.value));
    return candidates.first.value;
  }

  List<_AmountCandidate> _extractDerivedTotalCandidates(List<String> lines) {
    double? baseAmount;
    double? explicitNetTotal;
    final taxAmounts = <double>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      final amount = _extractBestAmountFromLine(line);
      if (amount == null) continue;

      if (RegExp(
        r'(grand\s*total|net\s*total|total\s*payable|amount\s*due|net\s*amount)',
        caseSensitive: false,
      ).hasMatch(lower)) {
        explicitNetTotal = explicitNetTotal == null
            ? amount
            : (amount > explicitNetTotal ? amount : explicitNetTotal);
        continue;
      }

      if (RegExp(
        r'(base\s*rate|taxable\s*value|subtotal|sub\s*total|base\s*amount)',
        caseSensitive: false,
      ).hasMatch(lower)) {
        baseAmount = baseAmount == null
            ? amount
            : (amount > baseAmount ? amount : baseAmount);
        continue;
      }

      if (RegExp(
        r'(cgst|sgst|igst|tax|cess)',
        caseSensitive: false,
      ).hasMatch(lower)) {
        taxAmounts.add(amount);
      }
    }

    final out = <_AmountCandidate>[];

    if (explicitNetTotal != null) {
      out.add(
        _AmountCandidate(
          value: explicitNetTotal,
          line: 'derived: explicit net total',
          hasCurrency: true,
          score: 14,
        ),
      );
    }

    if (baseAmount != null && taxAmounts.isNotEmpty) {
      final taxTotal = taxAmounts.fold<double>(0, (sum, e) => sum + e);
      final derived = baseAmount + taxTotal;
      if (derived > 1 && derived <= 5000000 && derived > baseAmount) {
        out.add(
          _AmountCandidate(
            value: derived,
            line: 'derived: base + tax',
            hasCurrency: true,
            score: 10 + (taxAmounts.length >= 2 ? 2 : 0),
          ),
        );
      }
    }

    return out;
  }

  List<_AmountCandidate> _extractCandidatesFromLine(String line) {
    final candidates = <_AmountCandidate>[];
    final usedRanges = <_Range>[];

    for (final match in _currencyAmountRegex.allMatches(line)) {
      final token = match.group(1);
      if (token == null) continue;

      final value = _parseAmountToken(token);
      if (value == null) continue;

      candidates.add(
        _AmountCandidate(
          value: value,
          line: line,
          hasCurrency: true,
          score: _scoreAmountCandidate(line, value, hasCurrency: true),
        ),
      );
      usedRanges.add(_Range(match.start, match.end));
    }

    for (final match in _plainAmountRegex.allMatches(line)) {
      final overlap = usedRanges.any((range) => range.overlaps(match.start, match.end));
      if (overlap) continue;

      final token = match.group(1);
      if (token == null) continue;

      final value = _parseAmountToken(token);
      if (value == null) continue;
      if (value < 1 || value > 5000000) continue;

      candidates.add(
        _AmountCandidate(
          value: value,
          line: line,
          hasCurrency: false,
          score: _scoreAmountCandidate(line, value, hasCurrency: false),
        ),
      );
    }

    return candidates;
  }

  double? _parseAmountToken(String token) {
    final raw = token.trim();

    String cleaned;
    if (raw.contains(',') && !raw.contains('.')) {
      // OCR sometimes reads decimal separator as comma (e.g. 210,04).
      if (RegExp(r'^\d+,\d{1,2}$').hasMatch(raw)) {
        cleaned = raw.replaceAll(',', '.');
      } else {
        cleaned = raw.replaceAll(',', '');
      }
    } else {
      cleaned = raw.replaceAll(',', '');
    }

    final value = double.tryParse(cleaned);
    if (value == null || value <= 0) return null;
    return value;
  }

  double? _extractBestAmountFromLine(String line) {
    final currencyValues = <double>[];
    for (final m in _currencyAmountRegex.allMatches(line)) {
      final token = m.group(1);
      if (token == null) continue;
      final value = _parseAmountToken(token);
      if (value == null) continue;
      currencyValues.add(value);
    }

    if (currencyValues.isNotEmpty) {
      return currencyValues.last;
    }

    final plainValues = <double>[];
    for (final m in _plainAmountRegex.allMatches(line)) {
      final token = m.group(1);
      if (token == null) continue;

      // Skip percentages like 2.5% from tax labels.
      final nextChar = m.end < line.length ? line[m.end] : '';
      if (nextChar == '%') continue;

      final value = _parseAmountToken(token);
      if (value == null) continue;
      plainValues.add(value);
    }

    return plainValues.isNotEmpty ? plainValues.last : null;
  }

  int _scoreAmountCandidate(String line, double value, {required bool hasCurrency}) {
    final lower = line.toLowerCase();
    var score = 0;

    if (hasCurrency) score += 6;
    if (_strongAmountKeywordsRegex.hasMatch(lower)) score += 6;
    if (_mediumAmountKeywordsRegex.hasMatch(lower)) score += 2;
    if (_noiseAmountKeywordsRegex.hasMatch(lower)) score -= 7;
    if (_taxKeywordsRegex.hasMatch(lower)) score -= 6;
    if (_dateHintRegex.hasMatch(lower)) score -= 3;

    if (RegExp(r'\bpaid\b', caseSensitive: false).hasMatch(lower) && hasCurrency) {
      score += 3;
    }
    if (RegExp(r'^\s*(\u20B9|rs|inr)', caseSensitive: false).hasMatch(line)) {
      score += 2;
    }

    final rounded = value.round();
    final isLikelyYear = rounded >= 1900 && rounded <= 2099 && value % 1 == 0;
    if (isLikelyYear && !hasCurrency) score -= 9;

    if (!hasCurrency && value >= 10000 && !_mediumAmountKeywordsRegex.hasMatch(lower)) {
      score -= 5;
    }

    if (value < 2) score -= 2;
    if (value >= 2 && value <= 5000000) score += 1;

    return score;
  }

  DateTime? _extractDate(List<String> lines) {
    final now = DateTime.now();
    DateTime? best;
    var bestScore = -999;

    for (final line in lines) {
      final lineDates = _extractDatesFromLine(line);
      if (lineDates.isEmpty) continue;

      final lower = line.toLowerCase();
      for (final date in lineDates) {
        var score = 0;

        if (RegExp(r'(paid|completed|transaction|payment)', caseSensitive: false)
            .hasMatch(lower)) {
          score += 6;
        }
        if (RegExp(r'(bill\s*date|invoice\s*date)', caseSensitive: false)
            .hasMatch(lower)) {
          score += 4;
        }
        if (RegExp(r'due\s*date', caseSensitive: false).hasMatch(lower)) {
          score -= 6;
        }

        final daysDiff = now.difference(date).inDays.abs();
        if (daysDiff <= 3) score += 4;
        if (daysDiff > 3 && daysDiff <= 30) score += 2;
        if (daysDiff > 30 && daysDiff <= 365) score += 1;

        if (date.isAfter(now.add(const Duration(days: 7)))) score -= 2;

        if (score > bestScore ||
            (score == bestScore && best != null && date.isAfter(best))) {
          bestScore = score;
          best = date;
        }
      }
    }

    if (best != null) return best;

    for (final line in lines) {
      final dates = _extractDatesFromLine(line);
      if (dates.isNotEmpty) return dates.first;
    }

    return null;
  }

  List<DateTime> _extractDatesFromLine(String line) {
    final dates = <DateTime>[];

    final dmy = RegExp(r'\b(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2,4})\b');
    for (final match in dmy.allMatches(line)) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      var year = int.tryParse(match.group(3)!);
      if (day == null || month == null || year == null) continue;
      if (year < 100) year += 2000;
      final parsed = _safeDate(year, month, day);
      if (parsed != null) dates.add(parsed);
    }

    final ymd = RegExp(r'\b(\d{4})[\/\.\-](\d{1,2})[\/\.\-](\d{1,2})\b');
    for (final match in ymd.allMatches(line)) {
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      if (day == null || month == null || year == null) continue;
      final parsed = _safeDate(year, month, day);
      if (parsed != null) dates.add(parsed);
    }

    final dMonY = RegExp(
      r'\b(\d{1,2})\s+([A-Za-z]{3,9})\s*,?\s*(\d{2,4})\b',
      caseSensitive: false,
    );
    for (final match in dMonY.allMatches(line)) {
      final day = int.tryParse(match.group(1)!);
      final month = _monthNumber(match.group(2)!);
      var year = int.tryParse(match.group(3)!);
      if (day == null || month == null || year == null) continue;
      if (year < 100) year += 2000;
      final parsed = _safeDate(year, month, day);
      if (parsed != null) dates.add(parsed);
    }

    final monDY = RegExp(
      r'\b([A-Za-z]{3,9})\s+(\d{1,2})\s*,?\s*(\d{2,4})\b',
      caseSensitive: false,
    );
    for (final match in monDY.allMatches(line)) {
      final month = _monthNumber(match.group(1)!);
      final day = int.tryParse(match.group(2)!);
      var year = int.tryParse(match.group(3)!);
      if (day == null || month == null || year == null) continue;
      if (year < 100) year += 2000;
      final parsed = _safeDate(year, month, day);
      if (parsed != null) dates.add(parsed);
    }

    return dates;
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (year < 2000 || year > 2100) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  int? _monthNumber(String token) {
    switch (token.trim().toLowerCase()) {
      case 'jan':
      case 'january':
        return 1;
      case 'feb':
      case 'february':
        return 2;
      case 'mar':
      case 'march':
        return 3;
      case 'apr':
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'jun':
      case 'june':
        return 6;
      case 'jul':
      case 'july':
        return 7;
      case 'aug':
      case 'august':
        return 8;
      case 'sep':
      case 'sept':
      case 'september':
        return 9;
      case 'oct':
      case 'october':
        return 10;
      case 'nov':
      case 'november':
        return 11;
      case 'dec':
      case 'december':
        return 12;
      default:
        return null;
    }
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

class _AmountCandidate {
  final double value;
  final String line;
  final bool hasCurrency;
  final int score;

  _AmountCandidate({
    required this.value,
    required this.line,
    required this.hasCurrency,
    required this.score,
  });
}

class _Range {
  final int start;
  final int end;

  _Range(this.start, this.end);

  bool overlaps(int otherStart, int otherEnd) {
    return start < otherEnd && otherStart < end;
  }
}
