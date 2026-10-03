import 'package:fpdart/fpdart.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';

abstract interface class PrayerPreferencesRepository {
  /// [PrayerLocation.cairo] until the user picks a city.
  ResultFuture<PrayerLocation> getLocation();

  ResultFuture<Unit> saveLocation(PrayerLocation location);

  ResultFuture<PrayerSettings> getSettings();

  ResultFuture<Unit> saveSettings(PrayerSettings settings);

  ResultFuture<AlertSettings> getAlerts();

  ResultFuture<Unit> saveAlerts(AlertSettings alerts);
}
