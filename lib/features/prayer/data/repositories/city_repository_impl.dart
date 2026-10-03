import 'package:injectable/injectable.dart';
import 'package:manara/core/error/guard.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/data/datasources/city_catalog_data_source.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/repositories/city_repository.dart';

@LazySingleton(as: CityRepository)
class CityRepositoryImpl implements CityRepository {
  CityRepositoryImpl(this._source);

  final CityCatalogDataSource _source;

  /// The list ships with the app, so it is read once.
  Future<List<PrayerLocation>>? _cities;

  @override
  ResultFuture<List<PrayerLocation>> getCities() {
    return guard(() {
      final future = _cities ??= _source.loadCities();
      // Forget a failed read so the next call tries again.
      return future.catchError((Object e, StackTrace stack) {
        _cities = null;
        Error.throwWithStackTrace(e, stack);
      });
    });
  }
}
