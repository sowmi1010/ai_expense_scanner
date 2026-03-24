import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../logging/app_logger.dart';

class NotificationInitResult {
  final bool initialized;
  final bool permissionsGranted;
  final String? message;

  const NotificationInitResult({
    required this.initialized,
    required this.permissionsGranted,
    this.message,
  });
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _permissionsGranted = true;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<NotificationInitResult> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const settings = InitializationSettings(android: android, iOS: ios);

      await _plugin.initialize(settings);
      _initialized = true;
    } catch (e) {
      _initialized = false;
      _permissionsGranted = false;
      return NotificationInitResult(
        initialized: false,
        permissionsGranted: false,
        message: 'Initialization failed: $e',
      );
    }

    var permissionsGranted = true;
    final warnings = <String>[];

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      try {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (granted == false) {
          permissionsGranted = false;
          warnings.add('iOS notification permission was denied.');
        }
      } catch (e) {
        permissionsGranted = false;
        warnings.add('iOS permission request failed: $e');
      }
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      try {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted == false) {
          permissionsGranted = false;
          warnings.add('Android notification permission was denied.');
        }
      } catch (e) {
        permissionsGranted = false;
        warnings.add('Android permission request failed: $e');
      }

      try {
        final enabled = await androidPlugin.areNotificationsEnabled();
        if (enabled == false) {
          permissionsGranted = false;
          warnings.add(
            'Android notifications are disabled in system settings.',
          );
        }
      } catch (e) {
        warnings.add('Could not verify Android notification settings: $e');
      }
    }

    _permissionsGranted = permissionsGranted;
    return NotificationInitResult(
      initialized: true,
      permissionsGranted: permissionsGranted,
      message: warnings.isEmpty ? null : warnings.join(' '),
    );
  }

  Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      AppLogger.warning(
        'NotificationService: skipped alert because init did not complete.',
      );
      return;
    }
    if (!_permissionsGranted) {
      AppLogger.warning(
        'NotificationService: skipped alert because notification permission is unavailable.',
      );
      return;
    }

    const android = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications when you reach budget limits',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
        title,
        body,
        details,
      );
    } catch (e) {
      AppLogger.error('NotificationService: failed to show alert.', error: e);
    }
  }
}
