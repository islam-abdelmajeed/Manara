import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/prayer_preferences_usecases.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/prayer_fixtures.dart';

class MockGetPrayerTimes extends Mock implements GetPrayerTimes {}

class MockGetLocation extends Mock implements GetPrayerLocation {}

class MockGetSettings extends Mock implements GetPrayerSettings {}

class MockSaveLocation extends Mock implements SavePrayerLocation {}

class MockSaveSettings extends Mock implements SavePrayerSettings {}

const _alexandria = PrayerLocation(
  id: 361058,
  name: 'الإسكندرية',
  nameEn: 'Alexandria',
  country: 'مصر',
  countryCode: 'EG',
  latitude: 31.20176,
  longitude: 29.91582,
  timeZone: 'Africa/Cairo',
);

const _hanafi = PrayerSettings(school: AsrSchool.hanafi);

void main() {
  late MockGetPrayerTimes getTimes;
  late MockGetLocation getLocation;
  late MockGetSettings getSettings;
  late MockSaveLocation saveLocation;
  late MockSaveSettings saveSettings;
  late DateTime now;

  setUpAll(() {
    registerFallbackValue(
      PrayerTimesParams(
        now: DateTime.utc(2026),
        location: PrayerLocation.cairo,
        settings: const PrayerSettings(),
      ),
    );
    registerFallbackValue(const NoParams());
    registerFallbackValue(PrayerLocation.cairo);
    registerFallbackValue(const PrayerSettings());
  });

  setUp(() {
    getTimes = MockGetPrayerTimes();
    getLocation = MockGetLocation();
    getSettings = MockGetSettings();
    saveLocation = MockSaveLocation();
    saveSettings = MockSaveSettings();
    when(() => saveLocation(any())).thenAnswer((_) async => const Right(unit));
    when(() => saveSettings(any())).thenAnswer((_) async => const Right(unit));
    now = cairo(10, 2, 12);
    when(
      () => getLocation(any()),
    ).thenAnswer((_) async => const Right(_alexandria));
    when(
      () => getSettings(any()),
    ).thenAnswer((_) async => const Right(_hanafi));
    when(() => getTimes(any())).thenAnswer((inv) async {
      final params = inv.positionalArguments.first as PrayerTimesParams;
      final october = cairoOctober();
      final today = october.dayAt(params.now)!;
      return Right(
        PrayerTimes(
          location: params.location,
          today: today,
          tomorrow: october.dayAfter(today)!,
        ),
      );
    });
  });

  PrayerTimesCubit build() => PrayerTimesCubit(
    getTimes,
    getLocation,
    getSettings,
    saveLocation,
    saveSettings,
    clock: () => now,
  );

  PrayerTimes timesOn(int day) {
    final october = cairoOctober();
    final today = october.allDays.firstWhere(
      (d) => d.date == DateTime.utc(2026, 10, day),
    );
    return PrayerTimes(
      location: _alexandria,
      today: today,
      tomorrow: october.dayAfter(today)!,
    );
  }

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'restores the saved city and settings, then loads today',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const PrayerTimesState(location: _alexandria, settings: _hanafi),
      const PrayerTimesState(
        status: PrayerTimesStatus.loading,
        location: _alexandria,
        settings: _hanafi,
      ),
      PrayerTimesState(
        status: PrayerTimesStatus.success,
        times: timesOn(2),
        location: _alexandria,
        settings: _hanafi,
      ),
    ],
    verify: (_) {
      final params =
          verify(() => getTimes(captureAny())).captured.single
              as PrayerTimesParams;
      expect(params.now, now);
      expect(params.location, _alexandria);
      expect(params.settings, _hanafi);
    },
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'falls back to Cairo and the defaults when preferences fail',
    setUp: () {
      when(
        () => getLocation(any()),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      when(
        () => getSettings(any()),
      ).thenAnswer((_) async => const Left(CacheFailure()));
    },
    build: build,
    act: (cubit) => cubit.load(),
    skip: 2,
    expect: () => [
      isA<PrayerTimesState>()
          .having((s) => s.location, 'location', PrayerLocation.cairo)
          .having((s) => s.settings, 'settings', const PrayerSettings())
          .having((s) => s.status, 'status', PrayerTimesStatus.success),
    ],
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'a failure keeps the times already shown',
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(
        () => getTimes(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      await cubit.retry();
    },
    skip: 3,
    expect: () => [
      PrayerTimesState(
        status: PrayerTimesStatus.loading,
        times: timesOn(2),
        location: _alexandria,
        settings: _hanafi,
      ),
      PrayerTimesState(
        status: PrayerTimesStatus.failure,
        times: timesOn(2),
        errorMessage: 'offline',
        location: _alexandria,
        settings: _hanafi,
      ),
    ],
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'load does nothing while today is shown',
    build: build,
    act: (cubit) async {
      await cubit.load();
      now = cairo(10, 2, 23, 59);
      await cubit.load();
    },
    verify: (_) => verify(() => getTimes(any())).called(1),
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'load fetches again once the day has changed',
    build: build,
    act: (cubit) async {
      await cubit.load();
      now = cairo(10, 3, 0, 1);
      await cubit.load();
    },
    verify: (cubit) {
      verify(() => getTimes(any())).called(2);
      expect(cubit.state.times!.today.date, DateTime.utc(2026, 10, 3));
    },
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'a slow, superseded response is dropped',
    build: build,
    act: (cubit) async {
      await cubit.load();
      final slow = Completer<Either<Failure, PrayerTimes>>();
      when(() => getTimes(any())).thenAnswer((_) => slow.future);
      final first = cubit.retry();

      when(() => getTimes(any())).thenAnswer((_) async => Right(timesOn(5)));
      await cubit.retry();

      slow.complete(Right(timesOn(9)));
      await first;
    },
    verify: (cubit) {
      expect(cubit.state.status, PrayerTimesStatus.success);
      expect(cubit.state.times, timesOn(5));
    },
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'changing the city clears the old times, saves it and reloads',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.changeLocation(PrayerLocation.cairo);
    },
    skip: 3,
    expect: () => [
      const PrayerTimesState(location: PrayerLocation.cairo, settings: _hanafi),
      const PrayerTimesState(
        status: PrayerTimesStatus.loading,
        location: PrayerLocation.cairo,
        settings: _hanafi,
      ),
      isA<PrayerTimesState>()
          .having((s) => s.status, 'status', PrayerTimesStatus.success)
          .having((s) => s.times?.location, 'times of', PrayerLocation.cairo),
    ],
    verify: (_) => verify(() => saveLocation(PrayerLocation.cairo)).called(1),
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'changing to the same city does nothing',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.changeLocation(_alexandria);
    },
    verify: (_) {
      verifyNever(() => saveLocation(any()));
      verify(() => getTimes(any())).called(1);
    },
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'a failed reload after a change does not show the old city',
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(
        () => getTimes(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      await cubit.changeLocation(PrayerLocation.cairo);
    },
    verify: (cubit) {
      expect(cubit.state.status, PrayerTimesStatus.failure);
      expect(cubit.state.times, isNull);
    },
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'changing the settings saves them and reloads with them',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.changeSettings(const PrayerSettings(hijriOffset: 1));
    },
    verify: (cubit) {
      verify(
        () => saveSettings(const PrayerSettings(hijriOffset: 1)),
      ).called(1);
      final params =
          verify(() => getTimes(captureAny())).captured.last
              as PrayerTimesParams;
      expect(params.settings, const PrayerSettings(hijriOffset: 1));
    },
  );

  test('reloads by itself at midnight in the location', () async {
    // 50 ms before midnight in Cairo.
    now = cairo(10, 3, 0).subtract(const Duration(milliseconds: 50));
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.times!.today.date, DateTime.utc(2026, 10, 2));

    now = cairo(10, 3, 0, 0, 1);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(cubit.state.status, PrayerTimesStatus.success);
    expect(cubit.state.times!.today.date, DateTime.utc(2026, 10, 3));
    verify(() => getTimes(any())).called(2);
  });

  test('a day that is over is reloaded at most once a minute', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();
    when(
      () => getTimes(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

    now = cairo(10, 3, 0, 0, 5);
    await cubit.refreshIfStale();
    now = cairo(10, 3, 0, 0, 30);
    await cubit.refreshIfStale();
    now = cairo(10, 3, 0, 1, 10);
    await cubit.refreshIfStale();

    // The first load, then two tries a minute apart.
    verify(() => getTimes(any())).called(3);
  });

  test('refreshIfStale does nothing while today is shown', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.refreshIfStale();
    verify(() => getTimes(any())).called(1);
  });

  test('close cancels the midnight reload', () async {
    now = cairo(10, 3, 0).subtract(const Duration(milliseconds: 50));
    final cubit = build();
    await cubit.load();
    await cubit.close();

    await Future<void>.delayed(const Duration(milliseconds: 200));
    verify(() => getTimes(any())).called(1);
  });
}
