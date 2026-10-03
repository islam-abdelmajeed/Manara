import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/platform/browser_actions.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/usecases/prayer_preferences_usecases.dart';

/// Shows an alert to the user. In the browser it is a system notification
/// once allowed; [permission] is `unsupported` elsewhere.
abstract interface class AlertNotifier {
  /// `granted`, `denied`, `default` or `unsupported`.
  String get permission;

  Future<String> requestPermission();

  void show(String title, String body);
}

@LazySingleton(as: AlertNotifier)
class BrowserAlertNotifier implements AlertNotifier {
  const BrowserAlertNotifier();

  @override
  String get permission => BrowserActions.notificationPermission;

  @override
  Future<String> requestPermission() =>
      BrowserActions.requestNotificationPermission();

  @override
  void show(String title, String body) => BrowserActions.notify(title, body);
}

class PrayerAlertsState extends Equatable {
  const PrayerAlertsState({
    this.settings = const AlertSettings(),
    this.permission = 'unsupported',
    this.loaded = false,
  });

  final AlertSettings settings;

  /// See [AlertNotifier.permission].
  final String permission;

  final bool loaded;

  /// System notifications can be shown.
  bool get canNotify => permission == 'granted';

  /// The browser could still be asked.
  bool get canAsk => permission == 'default';

  @override
  List<Object?> get props => [settings, permission, loaded];
}

/// The user's alert choices, provided above the router so alerts fire on
/// any screen while the app is open.
@injectable
class PrayerAlertsCubit extends Cubit<PrayerAlertsState> {
  PrayerAlertsCubit(this._get, this._save, this._notifier)
    : super(const PrayerAlertsState());

  final GetAlertSettings _get;
  final SaveAlertSettings _save;
  final AlertNotifier _notifier;

  Future<void> load() async {
    final result = await _get(const NoParams());
    if (isClosed) return;
    emit(
      PrayerAlertsState(
        settings: result.getOrElse((_) => const AlertSettings()),
        permission: _notifier.permission,
        loaded: true,
      ),
    );
  }

  /// Applies and saves [settings]. Turning the first alert on asks the
  /// browser for permission.
  Future<void> update(AlertSettings settings) async {
    final wasOff = !state.settings.anyEnabled;
    emit(
      PrayerAlertsState(
        settings: settings,
        permission: state.permission,
        loaded: true,
      ),
    );
    await _save(settings);
    if (wasOff && settings.anyEnabled && state.canAsk) {
      await requestPermission();
    }
  }

  Future<void> requestPermission() async {
    final permission = await _notifier.requestPermission();
    if (isClosed) return;
    emit(
      PrayerAlertsState(
        settings: state.settings,
        permission: permission,
        loaded: true,
      ),
    );
  }
}
