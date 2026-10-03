import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/prayer_preferences_usecases.dart';

enum PrayerTimesStatus { initial, loading, success, failure }

class PrayerTimesState extends Equatable {
  const PrayerTimesState({
    this.status = PrayerTimesStatus.initial,
    this.times,
    this.errorMessage,
    this.location = PrayerLocation.cairo,
    this.settings = const PrayerSettings(),
  });

  final PrayerTimesStatus status;

  /// Today's times; kept while reloading or after a failed reload.
  final PrayerTimes? times;

  final String? errorMessage;

  final PrayerLocation location;
  final PrayerSettings settings;

  PrayerTimesState copyWith({
    PrayerTimesStatus? status,
    PrayerTimes? times,
    String? Function()? errorMessage,
    PrayerLocation? location,
    PrayerSettings? settings,
  }) {
    return PrayerTimesState(
      status: status ?? this.status,
      times: times ?? this.times,
      errorMessage: errorMessage == null ? this.errorMessage : errorMessage(),
      location: location ?? this.location,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [status, times, errorMessage, location, settings];
}

/// Today's prayer times at the user's location. Provided once above the
/// router so the home page and the prayer section share it. Reloads itself
/// when the day changes at the location.
@injectable
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit(
    this._getPrayerTimes,
    this._getLocation,
    this._getSettings,
    this._saveLocation,
    this._saveSettings, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const PrayerTimesState());

  final GetPrayerTimes _getPrayerTimes;
  final GetPrayerLocation _getLocation;
  final GetPrayerSettings _getSettings;
  final SavePrayerLocation _saveLocation;
  final SavePrayerSettings _saveSettings;
  final DateTime Function() _clock;

  /// Identifies the latest request so slow, stale responses are dropped.
  int _requestId = 0;

  Future<void>? _restoring;
  Timer? _midnight;

  /// Loads today's times; a no-op while they are loading or already shown
  /// for the current day.
  Future<void> load() async {
    await _restore();
    if (isClosed) return;
    if (state.status == PrayerTimesStatus.loading) return;
    final times = state.times;
    if (state.status == PrayerTimesStatus.success &&
        times != null &&
        _isToday(times)) {
      return;
    }
    await _fetch();
  }

  /// Loads again whatever is shown (e.g. after a failure).
  Future<void> retry() => _fetch();

  /// Shortest wait between automatic reloads of a day that is over.
  static const Duration refreshInterval = Duration(minutes: 1);

  DateTime? _lastAttempt;

  /// Loads the new day once the shown one is over (called by the screens'
  /// one-second tickers). Tried at most once per [refreshInterval], so a
  /// failing network is not asked every second.
  Future<void> refreshIfStale() async {
    final times = state.times;
    if (isClosed || times == null || _isToday(times)) return;
    if (state.status == PrayerTimesStatus.loading) return;
    final last = _lastAttempt;
    if (last != null && _clock().difference(last) < refreshInterval) return;
    await _fetch();
  }

  /// Switches to [location], remembers it and reloads.
  Future<void> changeLocation(PrayerLocation location) async {
    // Restore first so the stored choice can't land after the user's.
    await _restore();
    if (isClosed || location == state.location) return;
    // The old city's times must not stay on screen under the new name.
    emit(PrayerTimesState(location: location, settings: state.settings));
    final saving = _saveLocation(location);
    await _fetch();
    await saving;
  }

  /// Switches to [settings], remembers them and reloads.
  Future<void> changeSettings(PrayerSettings settings) async {
    await _restore();
    if (isClosed || settings == state.settings) return;
    emit(PrayerTimesState(location: state.location, settings: settings));
    final saving = _saveSettings(settings);
    await _fetch();
    await saving;
  }

  Future<void> _restore() {
    return _restoring ??= () async {
      final location = await _getLocation(const NoParams());
      final settings = await _getSettings(const NoParams());
      if (isClosed) return;
      emit(
        state.copyWith(
          location: location.getOrElse((_) => PrayerLocation.cairo),
          settings: settings.getOrElse((_) => const PrayerSettings()),
        ),
      );
    }();
  }

  Future<void> _fetch() async {
    final request = ++_requestId;
    _lastAttempt = _clock();
    _midnight?.cancel();
    emit(
      state.copyWith(
        status: PrayerTimesStatus.loading,
        errorMessage: () => null,
      ),
    );

    final location = state.location;
    final result = await _getPrayerTimes(
      PrayerTimesParams(
        now: _clock(),
        location: location,
        settings: state.settings,
      ),
    );
    if (request != _requestId || isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(
          status: PrayerTimesStatus.failure,
          errorMessage: () => failure.message,
        ),
      ),
      (times) {
        emit(state.copyWith(status: PrayerTimesStatus.success, times: times));
        _scheduleMidnight(times);
      },
    );
  }

  /// Whether now falls on the loaded day, by the location's calendar.
  bool _isToday(PrayerTimes times) {
    final now = _clock();
    return !now.isBefore(times.today.start) &&
        now.isBefore(times.tomorrow.start);
  }

  void _scheduleMidnight(PrayerTimes times) {
    final wait = times.tomorrow.start.difference(_clock());
    _midnight = Timer(wait.isNegative ? Duration.zero : wait, () {
      if (!isClosed) unawaited(_fetch());
    });
  }

  @override
  Future<void> close() {
    _midnight?.cancel();
    return super.close();
  }
}
