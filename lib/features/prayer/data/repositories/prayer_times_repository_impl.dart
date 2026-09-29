import 'package:injectable/injectable.dart';
import 'package:manara/core/error/guard.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/data/datasources/prayer_times_remote_data_source.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/repositories/prayer_times_repository.dart';

@LazySingleton(as: PrayerTimesRepository)
class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  PrayerTimesRepositoryImpl(this._remote);

  final PrayerTimesRemoteDataSource _remote;
  final Map<String, PrayerTimes> _cache = {};

  @override
  ResultFuture<PrayerTimes> getPrayerTimes({
    required DateTime date,
    required PrayerLocation location,
  }) {
    final key =
        '${date.year}-${date.month}-${date.day}|${location.city}|${location.country}';
    return guard(() async {
      final cached = _cache[key];
      if (cached != null) return cached;
      return _cache[key] = await _remote.fetch(date: date, location: location);
    });
  }
}
