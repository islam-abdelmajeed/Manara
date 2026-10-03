import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/timezone.dart' as tz;

/// System notifications on Android and iOS (flutter_local_notifications),
/// shown now or scheduled for an instant, also while the app is closed.
/// Kept thin so the logic around it can be tested with a mock.
@lazySingleton
class LocalNotifications {
  LocalNotifications() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Android and iOS only; the web has its own notifications.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_alerts',
      'تنبيهات الصلاة',
      channelDescription: 'تنبيهات مواقيت الصلاة التي اخترتها.',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_manara',
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void>? _initializing;

  /// Permissions are asked for separately, when the user turns alerts on.
  Future<void> _ready() => _initializing ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_manara'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Whether notifications may be shown.
  Future<bool> enabled() async {
    await _ready();
    if (_android case final android?) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final options = await _ios?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  /// Asks the user (once; afterwards the system answers alone).
  Future<bool> requestPermission() async {
    await _ready();
    if (_android case final android?) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// Android 12+ may withhold exact alarms ("Alarms & reminders"); iOS
  /// always fires on time.
  Future<bool> canScheduleExact() async {
    await _ready();
    return await _android?.canScheduleExactNotifications() ?? true;
  }

  /// Opens the system setting for exact alarms on Android.
  Future<void> requestExact() async {
    await _ready();
    await _android?.requestExactAlarmsPermission();
  }

  Future<void> cancelAll() async {
    await _ready();
    await _plugin.cancelAll();
  }

  /// Shows a notification at [at] (any zone; it is an instant). Without
  /// [exact], Android may deliver it a few minutes late.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required bool exact,
  }) async {
    await _ready();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ready();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }
}
