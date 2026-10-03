import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/guard.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/data/datasources/prayer_local_data_source.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/repositories/prayer_preferences_repository.dart';

@LazySingleton(as: PrayerPreferencesRepository)
class PrayerPreferencesRepositoryImpl implements PrayerPreferencesRepository {
  const PrayerPreferencesRepositoryImpl(this._local);

  final PrayerLocalDataSource _local;

  @override
  ResultFuture<PrayerLocation> getLocation() {
    return guard(() async => _local.readLocation() ?? PrayerLocation.cairo);
  }

  @override
  ResultFuture<Unit> saveLocation(PrayerLocation location) {
    return guard(() async {
      await _local.writeLocation(location);
      return unit;
    });
  }

  @override
  ResultFuture<PrayerSettings> getSettings() {
    return guard(() async => _local.readSettings());
  }

  @override
  ResultFuture<Unit> saveSettings(PrayerSettings settings) {
    return guard(() async {
      await _local.writeSettings(settings);
      return unit;
    });
  }

  @override
  ResultFuture<AlertSettings> getAlerts() {
    return guard(() async => _local.readAlerts());
  }

  @override
  ResultFuture<Unit> saveAlerts(AlertSettings alerts) {
    return guard(() async {
      await _local.writeAlerts(alerts);
      return unit;
    });
  }
}
