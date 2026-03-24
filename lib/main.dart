import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_strings.dart';
import 'core/logging/app_logger.dart';
import 'state/providers/service_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(() {
    // Keep debug paint helpers off unless explicitly enabled during a debug session.
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintLayerBordersEnabled = false;
    debugPaintPointersEnabled = false;
    return true;
  }());

  final container = ProviderContainer();

  // Init local notifications (budget alerts) via DI.
  try {
    final initResult = await container.read(notificationServiceProvider).init();
    if (!initResult.initialized) {
      AppLogger.warning(
        'Notifications unavailable: ${initResult.message ?? AppStrings.unknownError}',
      );
    } else if (!initResult.permissionsGranted) {
      AppLogger.warning(
        'Notifications initialized but permission was not granted. ${initResult.message ?? ''}',
      );
    }
  } catch (e) {
    // Hard fallback: app should still launch even if notifications fail.
    AppLogger.error('Notification bootstrap failed.', error: e);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ExpenseScannerApp(),
    ),
  );
}
