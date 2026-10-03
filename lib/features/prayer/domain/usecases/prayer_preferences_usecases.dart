import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/repositories/prayer_preferences_repository.dart';

@injectable
class GetPrayerLocation implements UseCase<PrayerLocation, NoParams> {
  const GetPrayerLocation(this._repository);

  final PrayerPreferencesRepository _repository;

  @override
  ResultFuture<PrayerLocation> call(NoParams params) =>
      _repository.getLocation();
}

@injectable
class SavePrayerLocation implements UseCase<Unit, PrayerLocation> {
  const SavePrayerLocation(this._repository);

  final PrayerPreferencesRepository _repository;

  @override
  ResultFuture<Unit> call(PrayerLocation params) =>
      _repository.saveLocation(params);
}

@injectable
class GetPrayerSettings implements UseCase<PrayerSettings, NoParams> {
  const GetPrayerSettings(this._repository);

  final PrayerPreferencesRepository _repository;

  @override
  ResultFuture<PrayerSettings> call(NoParams params) =>
      _repository.getSettings();
}

@injectable
class SavePrayerSettings implements UseCase<Unit, PrayerSettings> {
  const SavePrayerSettings(this._repository);

  final PrayerPreferencesRepository _repository;

  @override
  ResultFuture<Unit> call(PrayerSettings params) =>
      _repository.saveSettings(params);
}

@injectable
class GetAlertSettings implements UseCase<AlertSettings, NoParams> {
  const GetAlertSettings(this._repository);

  final PrayerPreferencesRepository _repository;

  @override
  ResultFuture<AlertSettings> call(NoParams params) => _repository.getAlerts();
}

@injectable
class SaveAlertSettings implements UseCase<Unit, AlertSettings> {
  const SaveAlertSettings(this._repository);

  final PrayerPreferencesRepository _repository;

  @override
  ResultFuture<Unit> call(AlertSettings params) =>
      _repository.saveAlerts(params);
}
