import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/core/error/guard.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/data/datasources/prayer_local_data_source.dart';
import 'package:manara/features/prayer/data/datasources/prayer_times_remote_data_source.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/repositories/prayer_times_repository.dart';

/// Months are kept in memory and on disk. A month younger than [maxAge] is
/// used as is; an older one is downloaded again, because the HJCoSA Hijri
/// calendar follows moon-sighting announcements, and is still used when
/// the download fails (offline).
@LazySingleton(as: PrayerTimesRepository)
class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  PrayerTimesRepositoryImpl(
    this._remote,
    this._local, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const Duration maxAge = Duration(hours: 24);

  final PrayerTimesRemoteDataSource _remote;
  final PrayerLocalDataSource _local;
  final DateTime Function() _clock;

  final Map<String, PrayerMonth> _memory = {};

  /// Requests in flight, shared so the home page and the prayer section
  /// asking at once cause one download.
  final Map<String, Future<PrayerMonth>> _pending = {};

  static String cacheKey(
    PrayerLocation location,
    PrayerSettings settings,
    int year,
    int month,
  ) =>
      '${location.latitude},${location.longitude}|'
      '${settings.calculationKey}|$year-$month';

  @override
  ResultFuture<PrayerMonth> getMonth({
    required PrayerLocation location,
    required PrayerSettings settings,
    required int year,
    required int month,
  }) {
    return guard(() {
      final key = cacheKey(location, settings, year, month);
      final fresh = _fresh(_memory[key]);
      if (fresh != null) return Future.value(fresh);

      final pending = _pending[key];
      if (pending != null) return pending;

      final future = _load(key, location, settings, year, month);
      _pending[key] = future;
      unawaited(
        future.then<void>(
          (_) => _pending.remove(key),
          // A block body: returning the removed (failed) future would rethrow.
          onError: (Object _) {
            _pending.remove(key);
          },
        ),
      );
      return future;
    });
  }

  Future<PrayerMonth> _load(
    String key,
    PrayerLocation location,
    PrayerSettings settings,
    int year,
    int month,
  ) async {
    final cached = _local.readMonth(key);
    final fresh = _fresh(cached);
    if (fresh != null) return _memory[key] = fresh;

    try {
      final fetched = await _remote.fetchMonth(
        location: location,
        settings: settings,
        year: year,
        month: month,
      );
      final stamped = PrayerMonth(
        year: fetched.year,
        month: fetched.month,
        timeZone: fetched.timeZone,
        allDays: fetched.allDays,
        fetchedAt: _clock().toUtc(),
      );
      _memory[key] = stamped;
      try {
        await _local.writeMonth(key, stamped);
      } on Exception {
        // The times are still good; they just won't be there offline.
      }
      return stamped;
    } on NetworkException {
      if (cached != null) return cached;
      rethrow;
    } on ServerException {
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// [month] when it was fetched less than [maxAge] ago (and not in the
  /// future, which means the device clock moved back).
  PrayerMonth? _fresh(PrayerMonth? month) {
    final fetchedAt = month?.fetchedAt;
    if (fetchedAt == null) return null;
    final age = _clock().difference(fetchedAt);
    return age.isNegative || age >= maxAge ? null : month;
  }
}
