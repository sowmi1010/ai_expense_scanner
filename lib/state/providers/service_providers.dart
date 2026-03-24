import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/backup_service.dart';
import '../../core/services/budget_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/voice_service.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) => BudgetService());

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(service.dispose);
  return service;
});
