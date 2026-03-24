import 'package:flutter/material.dart';

import '../features/scan/receipt_camera_screen.dart';
import '../features/scan/receipt_preview_screen.dart';
import '../features/scan/scan_landing_screen.dart';
import '../features/settings/budget_settings_screen.dart';
import '../features/settings/export_backup_screen.dart';
import '../features/voice_assistant/voice_query_screen.dart';

class AppRoutes {
  static Future<T?> toScan<T>(BuildContext context) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => const ScanLandingScreen()));
  }

  static Future<T?> toCamera<T>(BuildContext context) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => const ReceiptCameraScreen()));
  }

  static Future<T?> toReceiptPreview<T>(
    BuildContext context, {
    String? imagePath,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewScreen(imagePath: imagePath),
      ),
    );
  }

  static Future<T?> toBudget<T>(BuildContext context) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => const BudgetSettingsScreen()));
  }

  static Future<T?> toExportBackup<T>(BuildContext context) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => const ExportBackupScreen()));
  }

  static Future<T?> toVoice<T>(BuildContext context) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => const VoiceQueryScreen()));
  }
}
