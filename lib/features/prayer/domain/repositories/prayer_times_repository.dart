import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

abstract interface class PrayerTimesRepository {
  /// Times of [month] of [year] at [location], padded by
  /// [PrayerMonth.padding] days on each side. Hijri dates are as calculated;
  /// [PrayerSettings.hijriOffset] is not applied here.
  ResultFuture<PrayerMonth> getMonth({
    required PrayerLocation location,
    required PrayerSettings settings,
    required int year,
    required int month,
  });
}
