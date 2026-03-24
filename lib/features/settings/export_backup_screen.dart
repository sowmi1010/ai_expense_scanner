import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../state/controllers/export_backup_controller.dart';

enum _ExportTask { none, csv, json, backup }

class ExportBackupScreen extends ConsumerStatefulWidget {
  const ExportBackupScreen({super.key});

  @override
  ConsumerState<ExportBackupScreen> createState() => _ExportBackupScreenState();
}

class _ExportBackupScreenState extends ConsumerState<ExportBackupScreen> {
  _ExportTask _activeTask = _ExportTask.none;

  bool get _busy => _activeTask != _ExportTask.none;

  Future<void> _shareFile(File file, String name) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Export: $name');
  }

  Future<void> _exportCsv() async {
    if (_busy) return;
    setState(() => _activeTask = _ExportTask.csv);
    try {
      final file = await ref
          .read(exportBackupControllerProvider)
          .exportCsvForCurrentMonth();
      await _shareFile(file, 'CSV');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export CSV failed: $e')));
    } finally {
      if (mounted) setState(() => _activeTask = _ExportTask.none);
    }
  }

  Future<void> _exportJson() async {
    if (_busy) return;
    setState(() => _activeTask = _ExportTask.json);
    try {
      final file = await ref
          .read(exportBackupControllerProvider)
          .exportJsonForCurrentMonth();
      await _shareFile(file, 'JSON');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export JSON failed: $e')));
    } finally {
      if (mounted) setState(() => _activeTask = _ExportTask.none);
    }
  }

  Future<void> _backupDb() async {
    if (_busy) return;
    setState(() => _activeTask = _ExportTask.backup);
    try {
      final file = await ref
          .read(exportBackupControllerProvider)
          .backupDatabaseSnapshot();
      await _shareFile(file, 'DB Backup');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _activeTask = _ExportTask.none);
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
                  if (_busy) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
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
                      icon: _activeTask == _ExportTask.csv
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.table_view_rounded),
                      label: Text(
                        _activeTask == _ExportTask.csv
                            ? 'Exporting CSV...'
                            : 'Export CSV (This month)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _exportJson,
                      icon: _activeTask == _ExportTask.json
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.data_object_rounded),
                      label: Text(
                        _activeTask == _ExportTask.json
                            ? 'Exporting JSON...'
                            : 'Export JSON (This month)',
                      ),
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
                      icon: _activeTask == _ExportTask.backup
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        _activeTask == _ExportTask.backup
                            ? 'Backing up...'
                            : 'Backup Database (DB file)',
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
