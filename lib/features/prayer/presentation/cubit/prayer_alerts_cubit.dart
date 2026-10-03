import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/prayer_preferences_usecases.dart';
import 'package:manara/features/prayer/presentation/cubit/alert_notifier.dart';
import 'package:manara/features/prayer/presentation/utils/alert_text.dart';

export 'package:manara/features/prayer/presentation/cubit/alert_notifier.dart';

class PrayerAlertsState extends Equatable {
  const PrayerAlertsState({
    this.settings = const AlertSettings(),
    this.permission = 'unsupported',
    this.exact = true,
    this.schedulesAhead = false,
    this.loaded = false,
  });

  final AlertSettings settings;

  /// See [AlertNotifier.checkPermission].
  final String permission;

  /// See [AlertNotifier.exactAllowed].
  final bool exact;

  /// See [AlertNotifier.schedulesAhead].
  final bool schedulesAhead;

  final bool loaded;

  /// System notifications can be shown.
  bool get canNotify => permission == 'granted';

  /// The user could still be asked.
  bool get canAsk => permission == 'default';

  PrayerAlertsState copyWith({
    AlertSettings? settings,
    String? permission,
    bool? exact,
  }) => PrayerAlertsState(
    settings: settings ?? this.settings,
    permission: permission ?? this.permission,
    exact: exact ?? this.exact,
    schedulesAhead: schedulesAhead,
    loaded: true,
  );

  @override
  List<Object?> get props => [
    settings,
    permission,
    exact,
    schedulesAhead,
    loaded,
  ];
}

/// The user's alert choices, provided above the router so alerts fire on
/// any screen while the app is open, and are kept scheduled with the system
/// on Android and iOS.
@injectable
class PrayerAlertsCubit extends Cubit<PrayerAlertsState> {
  PrayerAlertsCubit(
    this._get,
    this._save,
    this._notifier,
    this._upcomingDays, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const PrayerAlertsState());

  /// Days scheduled ahead with the system, refreshed whenever the app runs.
  static const int scheduleDays = 10;

  /// iOS keeps at most 64 pending notifications.
  static const int maxScheduled = 60;

  final GetAlertSettings _get;
  final SaveAlertSettings _save;
  final AlertNotifier _notifier;
  final GetUpcomingPrayerDays _upcomingDays;
  final DateTime Function() _clock;

  int _syncId = 0;

  Future<void> load() async {
    final result = await _get(const NoParams());
    final permission = await _notifier.checkPermission();
    final exact = await _notifier.exactAllowed();
    if (isClosed) return;
    emit(
      PrayerAlertsState(
        settings: result.getOrElse((_) => const AlertSettings()),
        permission: permission,
        exact: exact,
        schedulesAhead: _notifier.schedulesAhead,
        loaded: true,
      ),
    );
  }

  /// Applies and saves [settings]. Turning the first alert on asks for
  /// permission.
  Future<void> update(AlertSettings settings) async {
    final wasOff = !state.settings.anyEnabled;
    emit(state.copyWith(settings: settings));
    await _save(settings);
    if (wasOff && settings.anyEnabled && state.canAsk) {
      await requestPermission();
    }
  }

  Future<void> requestPermission() async {
    final permission = await _notifier.requestPermission();
    final exact = await _notifier.exactAllowed();
    if (isClosed) return;
    emit(state.copyWith(permission: permission, exact: exact));
  }

  /// Opens the system setting for exact alarms (Android).
  Future<void> requestExact() async {
    final exact = await _notifier.requestExact();
    if (isClosed) return;
    emit(state.copyWith(exact: exact));
  }

  /// Reads the permissions again, e.g. back from the system settings.
  Future<void> refreshPermission() async {
    if (!state.loaded) return;
    final permission = await _notifier.checkPermission();
    final exact = await _notifier.exactAllowed();
    if (isClosed) return;
    // A refusal in this run reads as "denied"; don't turn it back.
    emit(
      state.copyWith(
        permission: permission == 'default' ? state.permission : permission,
        exact: exact,
      ),
    );
  }

  /// Schedules the alerts of the coming [scheduleDays] at [location] with
  /// the system, replacing those set before; clears them when alerts are
  /// off or not allowed. Does nothing where alerts aren't scheduled ahead.
  Future<void> syncSystem(
    PrayerLocation location,
    PrayerSettings settings,
  ) async {
    if (!_notifier.schedulesAhead || !state.loaded) return;
    final request = ++_syncId;
    final alerts = state.settings;
    if (!state.canNotify || !alerts.anyEnabled) {
      await _notifier.schedule(const []);
      return;
    }
    final result = await _upcomingDays(
      UpcomingDaysParams(
        now: _clock(),
        location: location,
        settings: settings,
        count: scheduleDays,
      ),
    );
    // A newer sync took over; or no times: keep what is scheduled.
    if (request != _syncId || isClosed) return;
    final days = result.toNullable();
    if (days == null) return;
    final events = AlertEvent.upcoming(
      days,
      alerts,
      _clock(),
      limit: maxScheduled,
    );
    await _notifier.schedule([
      for (final event in events)
        if (alertText(event) case (final title, final body))
          ScheduledAlert(at: event.at, title: title, body: body),
    ]);
  }
}
