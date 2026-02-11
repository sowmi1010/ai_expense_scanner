import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/expense_model.dart';

class ExportService {
  ExportService._internal();
  static final ExportService instance = ExportService._internal();

  Future<File> exportCsv({
    required List<ExpenseModel> expenses,
    String fileName = 'expenses.csv',
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));

    final sb = StringBuffer();
    sb.writeln(
      'id,amount,merchant,category,payment_mode,created_at,receipt_image_path',
    );

    for (final e in expenses) {
      sb.writeln(
        [
          e.id ?? '',
          e.amount.toStringAsFixed(2),
          _csvSafe(e.merchant),
          _csvSafe(e.category),
          _csvSafe(e.paymentMode),
          e.createdAt.toIso8601String(),
          _csvSafe(e.receiptImagePath ?? ''),
        ].join(','),
      );
    }

    return file.writeAsString(sb.toString(), flush: true);
  }

  Future<File> exportJson({
    required List<ExpenseModel> expenses,
    String fileName = 'expenses.json',
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));

    final data = expenses.map((e) => e.toMap()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    return file.writeAsString(jsonStr, flush: true);
  }

  String _csvSafe(String v) {
    final s = v.replaceAll('"', '""');
    if (s.contains(',') || s.contains('\n')) return '"$s"';
    return s;
  }
}
