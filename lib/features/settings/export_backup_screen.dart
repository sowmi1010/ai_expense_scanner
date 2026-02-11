import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/export_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

class ExportBackupScreen extends StatefulWidget {
  const ExportBackupScreen({super.key});

  @override
  State<ExportBackupScreen> createState() => _ExportBackupScreenState();
}

class _ExportBackupScreenState extends State<ExportBackupScreen> {
  final _repo = ExpenseRepository.instance;

  bool _busy = false;

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _startOfNextMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  Future<List<ExpenseModel>> _getThisMonthExpenses() async {
    // We’ll add this method in repository in the next step (I’ll update your file)
    return _repo.getExpensesInRange(_startOfMonth(), _startOfNextMonth());
  }

  Future<void> _shareFile(File file, String name) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Export: $name');
  }

  Future<void> _exportCsv() async {
    setState(() => _busy = true);
    try {
      final list = await _getThisMonthExpenses();
      final file = await ExportService.instance.exportCsv(
        expenses: list,
        fileName: 'expenses_${DateTime.now().year}_${DateTime.now().month}.csv',
      );
      await _shareFile(file, 'CSV');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export CSV failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportJson() async {
    setState(() => _busy = true);
    try {
      final list = await _getThisMonthExpenses();
      final file = await ExportService.instance.exportJson(
        expenses: list,
        fileName:
            'expenses_${DateTime.now().year}_${DateTime.now().month}.json',
      );
      await _shareFile(file, 'JSON');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export JSON failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backupDb() async {
    setState(() => _busy = true);
    try {
      final file = await BackupService.instance.backupDatabaseToFile(
        fileName:
            'expense_ai_backup_${DateTime.now().year}_${DateTime.now().month}.db',
      );
      await _shareFile(file, 'DB Backup');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Export & Backup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Glass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Export this month transactions as CSV (Excel) or JSON.',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _exportCsv,
                      icon: const Icon(Icons.table_view_rounded),
                      label: const Text('Export CSV (This month)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _exportJson,
                      icon: const Icon(Icons.data_object_rounded),
                      label: const Text('Export JSON (This month)'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Glass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Backup your full database file. You can store it in Google Drive / Mail / WhatsApp.',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _backupDb,
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        _busy ? 'Working…' : 'Backup Database (DB file)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
