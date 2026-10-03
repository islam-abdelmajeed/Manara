import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/core/utils/arabic_search.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/qibla.dart';
import 'package:manara/features/prayer/domain/repositories/city_repository.dart';

/// A city and its great-circle distance from somewhere.
class CityDistance extends Equatable {
  const CityDistance(this.city, this.distanceKm);

  final PrayerLocation city;
  final double distanceKm;

  @override
  List<Object?> get props => [city, distanceKm];
}

class NearbyCitiesParams extends Equatable {
  const NearbyCitiesParams(this.from, {this.count = 10});

  final PrayerLocation from;
  final int count;

  @override
  List<Object?> get props => [from, count];
}

/// The [NearbyCitiesParams.count] nearest bundled cities, nearest first,
/// leaving out the location itself.
@injectable
class GetNearbyCities
    implements UseCase<List<CityDistance>, NearbyCitiesParams> {
  const GetNearbyCities(this._repository);

  final CityRepository _repository;

  @override
  ResultFuture<List<CityDistance>> call(NearbyCitiesParams params) async {
    final result = await _repository.getCities();
    return result.map((cities) {
      final from = params.from;
      final distances = [
        for (final city in cities)
          if (city.id != from.id)
            CityDistance(
              city,
              Qibla.distanceKmBetween(
                from.latitude,
                from.longitude,
                city.latitude,
                city.longitude,
              ),
            ),
      ]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return distances.take(params.count).toList();
    });
  }
}

class SearchCitiesParams extends Equatable {
  const SearchCitiesParams(this.query, {this.countryCode});

  final String query;

  /// Limits the results to one country (e.g. `EG`).
  final String? countryCode;

  @override
  List<Object?> get props => [query, countryCode];
}

/// Bundled cities whose Arabic or English name, or Arabic country name,
/// contains the query (loosely, see [ArabicSearch]); names that start with
/// it come first. An empty query lists every city.
@injectable
class SearchCities
    implements UseCase<List<PrayerLocation>, SearchCitiesParams> {
  const SearchCities(this._repository);

  final CityRepository _repository;

  @override
  ResultFuture<List<PrayerLocation>> call(SearchCitiesParams params) async {
    final result = await _repository.getCities();
    return result.map((cities) {
      final query = ArabicSearch.normalize(params.query);
      final inCountry = [
        for (final city in cities)
          if (params.countryCode == null ||
              city.countryCode == params.countryCode)
            city,
      ];
      if (query.isEmpty) return inCountry;

      final starts = <PrayerLocation>[];
      final contains = <PrayerLocation>[];
      for (final city in inCountry) {
        final names = [city.name, city.nameEn].map(ArabicSearch.normalize);
        if (names.any((n) => n.startsWith(query) || n.startsWith('ال$query'))) {
          starts.add(city);
        } else if (names.any((n) => n.contains(query)) ||
            ArabicSearch.normalize(city.country).contains(query)) {
          contains.add(city);
        }
      }
      return [...starts, ...contains];
    });
  }
}
