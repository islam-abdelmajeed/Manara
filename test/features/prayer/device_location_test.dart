import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/data/datasources/city_catalog_data_source.dart';
import 'package:manara/features/prayer/data/repositories/city_repository_impl.dart';
import 'package:manara/features/prayer/data/repositories/device_location_repository_impl.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/repositories/device_location_repository.dart';
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart';
import 'package:manara/features/prayer/presentation/cubit/device_location_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockGeolocator extends Mock implements GeolocatorPlatform {}

class MockDeviceLocation extends Mock implements DeviceLocationRepository {}

class MockLocateDevice extends Mock implements LocateDevice {}

/// Serves files from the project folder, like the app's bundle.
class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}

Position _at(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime.utc(2026, 10, 3),
  accuracy: 2000,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(LocationProblem.denied);
  });

  group('DeviceLocationRepositoryImpl', () {
    late MockGeolocator geolocator;
    late DeviceLocationRepositoryImpl repository;

    setUp(() {
      geolocator = MockGeolocator();
      repository = DeviceLocationRepositoryImpl(geolocator);
      when(
        () => geolocator.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => geolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => _at(30.0444, 31.2357));
    });

    Future<Either<Failure, ({double latitude, double longitude})>> current() =>
        repository.current();

    test('the position, asked at low accuracy', () async {
      expect(
        await current(),
        const Right((latitude: 30.0444, longitude: 31.2357)),
      );
      final settings =
          verify(
                () => geolocator.getCurrentPosition(
                  locationSettings: captureAny(named: 'locationSettings'),
                ),
              ).captured.single
              as LocationSettings;
      expect(settings.accuracy, LocationAccuracy.low);
      expect(settings.timeLimit, isNotNull);
    });

    test('asks once when not yet decided', () async {
      when(
        () => geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => geolocator.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      expect((await current()).isRight(), isTrue);
      verify(() => geolocator.requestPermission()).called(1);
    });

    test('a refusal is "denied"', () async {
      when(
        () => geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => geolocator.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      expect(
        await current(),
        const Left(LocationFailure(LocationProblem.denied)),
      );
    });

    test('blocked for good: not asked again', () async {
      when(
        () => geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);
      expect(
        await current(),
        const Left(LocationFailure(LocationProblem.deniedForever)),
      );
      verifyNever(() => geolocator.requestPermission());
    });

    test('location services off', () async {
      when(
        () => geolocator.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);
      expect(
        await current(),
        const Left(LocationFailure(LocationProblem.serviceOff)),
      );
      verifyNever(() => geolocator.checkPermission());
    });

    test('no fix in time is "unavailable"', () async {
      when(
        () => geolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(TimeoutException('no fix'));
      expect(
        await current(),
        const Left(LocationFailure(LocationProblem.unavailable)),
      );
    });

    test('opens the settings that fix the problem', () async {
      when(
        () => geolocator.openLocationSettings(),
      ).thenAnswer((_) async => true);
      when(() => geolocator.openAppSettings()).thenAnswer((_) async => true);
      await repository.openSettings(LocationProblem.serviceOff);
      verify(() => geolocator.openLocationSettings()).called(1);
      await repository.openSettings(LocationProblem.deniedForever);
      verify(() => geolocator.openAppSettings()).called(1);
    });
  });

  group('LocateDevice', () {
    late MockDeviceLocation device;
    late LocateDevice locate;

    setUp(() {
      device = MockDeviceLocation();
      locate = LocateDevice(
        device,
        CityRepositoryImpl(CityCatalogDataSourceImpl(_FileBundle())),
      );
    });

    void at(double latitude, double longitude) =>
        when(() => device.current()).thenAnswer(
          (_) async => Right((latitude: latitude, longitude: longitude)),
        );

    test('named after the nearest city, at about 100 m', () async {
      // The Giza pyramids: Giza (GeoNames 360995) is the nearest listed city.
      at(29.97923, 31.13420);
      final here = (await locate(
        const NoParams(),
      )).getOrElse((f) => throw StateError(f.message));
      expect(
        here,
        const PrayerLocation(
          id: PrayerLocation.deviceId,
          name: 'قرب الجيزة',
          nameEn: 'Near Giza',
          country: 'مصر',
          countryCode: 'EG',
          latitude: 29.979,
          longitude: 31.134,
          timeZone: 'Africa/Cairo',
        ),
      );
      expect(here.isDevice, isTrue);
    });

    test('far from every city it is "my location"', () async {
      at(0, -30); // The middle of the Atlantic.
      final here = (await locate(
        const NoParams(),
      )).getOrElse((f) => throw StateError(f.message));
      expect(here.name, 'موقعي الحالي');
      expect(here.latitude, 0);
      expect(here.longitude, -30);
    });

    test("the device's failure is the result", () async {
      when(() => device.current()).thenAnswer(
        (_) async => const Left(LocationFailure(LocationProblem.denied)),
      );
      expect(
        await locate(const NoParams()),
        const Left(LocationFailure(LocationProblem.denied)),
      );
    });
  });

  group('DeviceLocationCubit', () {
    late MockLocateDevice locate;
    late MockDeviceLocation device;

    const here = PrayerLocation(
      id: PrayerLocation.deviceId,
      name: 'قرب الجيزة',
      nameEn: 'Near Giza',
      country: 'مصر',
      countryCode: 'EG',
      latitude: 29.979,
      longitude: 31.134,
      timeZone: 'Africa/Cairo',
    );

    setUp(() {
      locate = MockLocateDevice();
      device = MockDeviceLocation();
      when(() => device.openSettings(any())).thenAnswer((_) async {});
    });

    blocTest<DeviceLocationCubit, DeviceLocationState>(
      'locating, then the location',
      setUp: () =>
          when(() => locate(any())).thenAnswer((_) async => const Right(here)),
      build: () => DeviceLocationCubit(locate, device),
      act: (cubit) => cubit.locate(),
      expect: () => const [
        DeviceLocationState(status: DeviceLocationStatus.locating),
        DeviceLocationState(
          status: DeviceLocationStatus.located,
          location: here,
        ),
      ],
    );

    blocTest<DeviceLocationCubit, DeviceLocationState>(
      'a blocked permission needs the settings, and opens them',
      setUp: () => when(() => locate(any())).thenAnswer(
        (_) async => const Left(LocationFailure(LocationProblem.deniedForever)),
      ),
      build: () => DeviceLocationCubit(locate, device),
      act: (cubit) async {
        await cubit.locate();
        await cubit.openSettings();
      },
      verify: (cubit) {
        expect(cubit.state.needsSettings, isTrue);
        verify(
          () => device.openSettings(LocationProblem.deniedForever),
        ).called(1);
      },
    );

    blocTest<DeviceLocationCubit, DeviceLocationState>(
      'a plain refusal needs no settings',
      setUp: () => when(() => locate(any())).thenAnswer(
        (_) async => const Left(LocationFailure(LocationProblem.denied)),
      ),
      build: () => DeviceLocationCubit(locate, device),
      act: (cubit) => cubit.locate(),
      verify: (cubit) => expect(cubit.state.needsSettings, isFalse),
    );

    blocTest<DeviceLocationCubit, DeviceLocationState>(
      'a second tap while locating is ignored',
      setUp: () =>
          when(() => locate(any())).thenAnswer((_) async => const Right(here)),
      build: () => DeviceLocationCubit(locate, device),
      act: (cubit) => Future.wait([cubit.locate(), cubit.locate()]),
      verify: (_) => verify(() => locate(any())).called(1),
    );
  });
}
