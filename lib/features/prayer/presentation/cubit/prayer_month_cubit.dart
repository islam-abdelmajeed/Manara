import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';

enum PrayerMonthStatus { initial, loading, success, failure }

class PrayerMonthState extends Equatable {
  const PrayerMonthState({
    this.year = 0,
    this.month = 0,
    this.status = PrayerMonthStatus.initial,
    this.data,
    this.errorMessage,
  });

  /// The month asked for (shown even while it loads).
  final int year;
  final int month;

  final PrayerMonthStatus status;

  /// The loaded month; only set when it is [year]/[month].
  final PrayerMonth? data;

  final String? errorMessage;

  @override
  List<Object?> get props => [year, month, status, data, errorMessage];
}

/// One month of times for the monthly table. Shares the repository's cache
/// with the home page, so the current month is not downloaded twice.
@injectable
class PrayerMonthCubit extends Cubit<PrayerMonthState> {
  PrayerMonthCubit(this._getMonth) : super(const PrayerMonthState());

  final GetPrayerMonth _getMonth;

  PrayerLocation? _location;
  PrayerSettings? _settings;
  int _requestId = 0;

  /// Shows [year]/[month] for [location] with [settings]; a no-op when that
  /// is already shown or loading.
  Future<void> show({
    required int year,
    required int month,
    required PrayerLocation location,
    required PrayerSettings settings,
  }) async {
    // Normalise e.g. month 13 to January of the next year.
    final first = DateTime.utc(year, month);
    if (first.year == state.year &&
        first.month == state.month &&
        location == _location &&
        settings == _settings &&
        state.status != PrayerMonthStatus.failure) {
      return;
    }
    _location = location;
    _settings = settings;
    await _fetch(first.year, first.month);
  }

  /// The month before or after the one shown.
  Future<void> step(int months) async {
    final location = _location;
    final settings = _settings;
    if (location == null || settings == null) return;
    await show(
      year: state.year,
      month: state.month + months,
      location: location,
      settings: settings,
    );
  }

  Future<void> retry() async {
    if (_location == null) return;
    await _fetch(state.year, state.month);
  }

  Future<void> _fetch(int year, int month) async {
    final request = ++_requestId;
    emit(
      PrayerMonthState(
        year: year,
        month: month,
        status: PrayerMonthStatus.loading,
      ),
    );
    final result = await _getMonth(
      PrayerMonthParams(
        location: _location!,
        settings: _settings!,
        year: year,
        month: month,
      ),
    );
    if (request != _requestId || isClosed) return;
    emit(
      result.match(
        (failure) => PrayerMonthState(
          year: year,
          month: month,
          status: PrayerMonthStatus.failure,
          errorMessage: failure.message,
        ),
        (data) => PrayerMonthState(
          year: year,
          month: month,
          status: PrayerMonthStatus.success,
          data: data,
        ),
      ),
    );
  }
}
