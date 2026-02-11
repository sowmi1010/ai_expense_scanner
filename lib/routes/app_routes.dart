import 'package:flutter/material.dart';

import '../features/scan/receipt_camera_screen.dart';
import '../features/scan/receipt_preview_screen.dart';
import '../features/scan/scan_landing_screen.dart';
import '../features/settings/budget_settings_screen.dart';
import '../features/settings/export_backup_screen.dart';
import '../features/shell/shell_screen.dart';
import '../features/voice_assistant/voice_query_screen.dart';

class AppRoutes {
  static const shell = '/';
  static const scan = '/scan';
  static const camera = '/camera';
  static const receiptPreview = '/receipt-preview';
  static const budget = '/budget';
  static const exportBackup = '/export-backup';
  static const voice = '/voice';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case shell:
        return MaterialPageRoute(builder: (_) => const ShellScreen());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanLandingScreen());
      case camera:
        return MaterialPageRoute(builder: (_) => const ReceiptCameraScreen());
      case receiptPreview:
        return MaterialPageRoute(builder: (_) => const ReceiptPreviewScreen());
      case budget:
        return MaterialPageRoute(builder: (_) => const BudgetSettingsScreen());
      case exportBackup:
        return MaterialPageRoute(builder: (_) => const ExportBackupScreen());
      case voice:
        return MaterialPageRoute(builder: (_) => const VoiceQueryScreen());
      default:
        return MaterialPageRoute(builder: (_) => const ShellScreen());
    }
  }
}
