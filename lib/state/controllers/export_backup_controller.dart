import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/backup_service.dart';
import '../../core/services/export_service.dart';
import '../../data/repositories/expense_repo.dart';
import '../providers/expense_providers.dart';
import '../providers/service_providers.dart';

final exportBackupControllerProvider = Provider<ExportBackupController>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final exportService = ref.watch(exportServiceProvider);
  final backupService = ref.watch(backupServiceProvider);
  return ExportBackupController(
    repo: repo,
    exportService: exportService,
    backupService: backupService,
  );
});

class ExportBackupController {
  final ExpenseRepo _repo;
  final ExportService _exportService;
  final BackupService _backupService;

  ExportBackupController({
    required ExpenseRepo repo,
    required ExportService exportService,
    required BackupService backupService,
  }) : _repo = repo,
       _exportService = exportService,
       _backupService = backupService;

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _startOfNextMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  Future<File> exportCsvForCurrentMonth() async {
    final now = DateTime.now();
    final expenses = await _repo.getExpensesInRange(
      _startOfMonth(),
      _startOfNextMonth(),
    );
    return _exportService.exportCsv(
      expenses: expenses,
      fileName: 'expenses_${now.year}_${now.month}.csv',
    );
  }

  Future<File> exportJsonForCurrentMonth() async {
    final now = DateTime.now();
    final expenses = await _repo.getExpensesInRange(
      _startOfMonth(),
      _startOfNextMonth(),
    );
    return _exportService.exportJson(
      expenses: expenses,
      fileName: 'expenses_${now.year}_${now.month}.json',
    );
  }

  Future<File> backupDatabaseSnapshot() async {
    final now = DateTime.now();
    return _backupService.backupDatabaseToFile(
      fileName: 'expense_ai_backup_${now.year}_${now.month}.db',
    );
  }
}
