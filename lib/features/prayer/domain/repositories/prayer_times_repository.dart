import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

abstract interface class PrayerTimesRepository {
  ResultFuture<PrayerTimes> getPrayerTimes({
    required DateTime date,
    required PrayerLocation location,
  });
}
