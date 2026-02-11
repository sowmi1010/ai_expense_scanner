import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'app.dart';
import 'core/services/notification_service.dart';

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

  // Init local notifications (budget alerts).
  await NotificationService.instance.init();

  runApp(const ExpenseScannerApp());
}
