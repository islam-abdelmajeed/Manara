import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/platform/browser_actions.dart';
import 'package:manara/core/platform/local_notifications.dart';

/// An alert handed to the system ahead of time.
class ScheduledAlert extends Equatable {
  const ScheduledAlert({
    required this.at,
    required this.title,
    required this.body,
  });

  final DateTime at;
  final String title;
  final String body;

  @override
  List<Object?> get props => [at, title, body];
}

/// Shows prayer alerts to the user: in the browser as a notification while
/// the tab is open; on Android and iOS scheduled with the system, so they
/// fire while the app is closed.
abstract interface class AlertNotifier {
  /// Alerts are scheduled with the system ([schedule]) instead of being
  /// shown by the open app ([show]).
  bool get schedulesAhead;

  /// `granted`, `denied`, `default` (may ask) or `unsupported`.
  Future<String> checkPermission();

  Future<String> requestPermission();

  /// Whether scheduled alerts fire at their minute (Android may withhold
  /// exact alarms; they then come a few minutes late).
  Future<bool> exactAllowed();

  /// Opens the system setting for exact alarms; whether they are allowed.
  Future<bool> requestExact();

  void show(String title, String body);

  /// Replaces every alert scheduled before with [alerts].
  Future<void> schedule(List<ScheduledAlert> alerts);
}

@module
abstract class AlertNotifierModule {
  @lazySingleton
  AlertNotifier alertNotifier(LocalNotifications local) =>
      LocalNotifications.supported
      ? DeviceAlertNotifier(local)
      : const BrowserAlertNotifier();
}

/// The web's Notification API; `unsupported` on other platforms, where
/// alerts then show inside the open app.
class BrowserAlertNotifier implements AlertNotifier {
  const BrowserAlertNotifier();

  @override
  bool get schedulesAhead => false;

  @override
  Future<String> checkPermission() async =>
      BrowserActions.notificationPermission;

  @override
  Future<String> requestPermission() =>
      BrowserActions.requestNotificationPermission();

  @override
  Future<bool> exactAllowed() async => true;

  @override
  Future<bool> requestExact() async => true;

  @override
  void show(String title, String body) => BrowserActions.notify(title, body);

  @override
  Future<void> schedule(List<ScheduledAlert> alerts) async {}
}

/// Android and iOS: alerts are scheduled with the system. Should the
/// plugin fail, it reads as `unsupported` and alerts show in the open app.
class DeviceAlertNotifier implements AlertNotifier {
  DeviceAlertNotifier(this._local);

  final LocalNotifications _local;

  /// The user refused in this run; the system won't ask again, so the note
  /// says to change it in the device settings.
  bool _refused = false;

  /// Schedules run one after another, so an older list can't land last.
  Future<void> _queue = Future.value();

  /// Above every scheduled id.
  static const int _shownId = 1000;

  @override
  bool get schedulesAhead => true;

  @override
  Future<String> checkPermission() => _guard(() async {
    if (await _local.enabled()) return 'granted';
    return _refused ? 'denied' : 'default';
  }, 'unsupported');

  @override
  Future<String> requestPermission() => _guard(() async {
    final granted = await _local.requestPermission();
    _refused = !granted;
    return granted ? 'granted' : 'denied';
  }, 'unsupported');

  @override
  Future<bool> exactAllowed() => _guard(_local.canScheduleExact, true);

  @override
  Future<bool> requestExact() => _guard(() async {
    await _local.requestExact();
    return _local.canScheduleExact();
  }, true);

  Future<T> _guard<T>(Future<T> Function() call, T fallback) async {
    try {
      return await call();
      // Also Errors: an unregistered plugin throws a LateError.
    } catch (error) {
      debugPrint('Notifications unavailable: $error');
      return fallback;
    }
  }

  @override
  void show(String title, String body) => unawaited(
    _guard(() => _local.show(id: _shownId, title: title, body: body), null),
  );

  @override
  Future<void> schedule(List<ScheduledAlert> alerts) =>
      _queue = _queue.then((_) => _replace(alerts));

  Future<void> _replace(List<ScheduledAlert> alerts) async {
    try {
      await _local.cancelAll();
      if (alerts.isEmpty) return;
      final exact = await _local.canScheduleExact();
      for (final (id, alert) in alerts.indexed) {
        await _local.schedule(
          id: id,
          at: alert.at,
          title: alert.title,
          body: alert.body,
          exact: exact,
        );
      }
    } catch (error) {
      // Exact alarms can be withdrawn between the check and the call; the
      // next schedule (app opened, times refreshed) sets them again.
      debugPrint('Prayer alerts not scheduled: $error');
    }
  }
}
