import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/prayer/data/datasources/city_catalog_data_source.dart';
import 'package:manara/features/prayer/data/repositories/city_repository_impl.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/repositories/city_repository.dart';
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart';
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart';
import 'package:mocktail/mocktail.dart';

/// Serves files from the project folder, like the app's bundle.
class _FileBundle extends CachingAssetBundle {
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

class _BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList('{"not": "a list"}'.codeUnits));
}

class MockCityRepository extends Mock implements CityRepository {}

void main() {
  late _FileBundle bundle;
  late CityRepositoryImpl repository;

  setUp(() {
    bundle = _FileBundle();
    repository = CityRepositoryImpl(CityCatalogDataSourceImpl(bundle));
  });

  Future<List<PrayerLocation>> cities() async => (await repository.getCities())
      .getOrElse((f) => throw StateError(f.message));

  group('bundled city list', () {
    test('reads every city, with Cairo as in PrayerLocation.cairo', () async {
      final all = await cities();
      expect(all.length, greaterThan(150));
      expect(all.where((c) => c.id == 360630).single, PrayerLocation.cairo);
    });

    test('every city has Arabic names, coordinates and a zone', () async {
      final arabic = RegExp(r'^[؀-ۿ ،()\-]+$');
      for (final c in await cities()) {
        expect(c.name, matches(arabic), reason: c.nameEn);
        expect(c.country, matches(arabic), reason: c.nameEn);
        expect(c.latitude, inInclusiveRange(-90, 90));
        expect(c.longitude, inInclusiveRange(-180, 180));
        expect(c.timeZone, contains('/'));
        expect(c.countryCode, hasLength(2));
      }
    });

    test('ids are unique', () async {
      final all = await cities();
      expect(all.map((c) => c.id).toSet(), hasLength(all.length));
    });

    test('has every Egyptian governorate capital', () async {
      final egypt = (await cities()).where((c) => c.countryCode == 'EG');
      expect(egypt, hasLength(27));
    });

    test('Jerusalem is "القدس" under Palestine (owner decision)', () async {
      final quds = (await cities()).where((c) => c.id == 7303419).single;
      expect(quds.name, 'القدس');
      expect(quds.countryCode, 'PS');
      expect(quds.country, 'فلسطين');
    });

    test('is read from the bundle once', () async {
      await cities();
      await cities();
      expect(bundle.loads, 1);
    });

    test('an unreadable list is a CacheFailure, and is retried', () async {
      repository = CityRepositoryImpl(
        CityCatalogDataSourceImpl(_BrokenBundle()),
      );
      final first = await repository.getCities();
      expect(first.swap().toNullable(), isA<CacheFailure>());
      final second = await repository.getCities();
      expect(second.isLeft(), isTrue);
    });
  });

  group('GetNearbyCities', () {
    test('nearest first, without the city itself', () async {
      final result = await GetNearbyCities(repository)(
        const NearbyCitiesParams(PrayerLocation.cairo, count: 3),
      );
      final nearby = result.getOrElse((_) => []);
      expect(nearby, hasLength(3));
      expect(nearby.first.city.nameEn, 'Giza');
      expect(nearby.first.distanceKm, closeTo(7.11, 0.01));
      expect(nearby.map((c) => c.city.id), isNot(contains(360630)));
      expect(
        nearby.map((c) => c.distanceKm).toList(),
        orderedEquals([...nearby.map((c) => c.distanceKm)]..sort()),
      );
    });
  });

  group('SearchCities', () {
    Future<List<String>> search(String q, {String? country}) async {
      final result = await SearchCities(repository)(
        SearchCitiesParams(q, countryCode: country),
      );
      return result.getOrElse((_) => []).map((c) => c.name).toList();
    }

    test('matches Arabic names loosely', () async {
      expect(await search('القاهرة'), contains('القاهرة'));
      // Without "ال", with a bare alef, or with diacritics.
      expect((await search('قاهره')).first, 'القاهرة');
      expect(await search('الاسكندرية'), contains('الإسكندرية'));
      expect(await search('القَاهِرَة'), contains('القاهرة'));
    });

    test('matches English names', () async {
      expect(await search('Cairo'), ['القاهرة']);
      expect(await search('cai'), contains('القاهرة'));
    });

    test('matches the country name', () async {
      expect(await search('السعودية'), contains('الرياض'));
    });

    test('limits to a country', () async {
      final egypt = await search('', country: 'EG');
      expect(egypt, hasLength(27));
      expect(await search('الرياض', country: 'EG'), isEmpty);
    });

    test('nothing matches nonsense', () async {
      expect(await search('zzzqqq'), isEmpty);
    });
  });

  group('NearbyCitiesCubit', () {
    late MockCityRepository mockRepository;
    const giza = PrayerLocation(
      id: 360995,
      name: 'الجيزة',
      nameEn: 'Giza',
      country: 'مصر',
      countryCode: 'EG',
      latitude: 30.00944,
      longitude: 31.20861,
      timeZone: 'Africa/Cairo',
    );

    setUp(() => mockRepository = MockCityRepository());

    blocTest<NearbyCitiesCubit, NearbyCitiesState>(
      'loads the cities near a location',
      setUp: () => when(
        () => mockRepository.getCities(),
      ).thenAnswer((_) async => const Right([PrayerLocation.cairo, giza])),
      build: () => NearbyCitiesCubit(GetNearbyCities(mockRepository)),
      act: (cubit) => cubit.load(PrayerLocation.cairo),
      expect: () => [
        isA<NearbyCitiesState>()
            .having((s) => s.from, 'from', PrayerLocation.cairo)
            .having((s) => s.cities.map((c) => c.city), 'cities', [giza]),
      ],
    );

    blocTest<NearbyCitiesCubit, NearbyCitiesState>(
      'a failure leaves the list empty',
      setUp: () => when(
        () => mockRepository.getCities(),
      ).thenAnswer((_) async => const Left(CacheFailure())),
      build: () => NearbyCitiesCubit(GetNearbyCities(mockRepository)),
      act: (cubit) => cubit.load(PrayerLocation.cairo),
      expect: () => [const NearbyCitiesState(from: PrayerLocation.cairo)],
    );

    blocTest<NearbyCitiesCubit, NearbyCitiesState>(
      'loading the same location again does nothing',
      setUp: () => when(
        () => mockRepository.getCities(),
      ).thenAnswer((_) async => const Right([PrayerLocation.cairo, giza])),
      build: () => NearbyCitiesCubit(GetNearbyCities(mockRepository)),
      act: (cubit) async {
        await cubit.load(PrayerLocation.cairo);
        await cubit.load(PrayerLocation.cairo);
      },
      verify: (_) => verify(() => mockRepository.getCities()).called(1),
    );
  });
}
