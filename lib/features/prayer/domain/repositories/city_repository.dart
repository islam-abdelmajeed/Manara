import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';

abstract interface class CityRepository {
  ResultFuture<List<PrayerLocation>> getCities();
}
