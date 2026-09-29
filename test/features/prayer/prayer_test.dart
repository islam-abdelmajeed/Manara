import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/prayer/data/datasources/prayer_times_remote_data_source.dart';
import 'package:manara/features/prayer/data/models/prayer_times_model.dart';
import 'package:manara/features/prayer/data/repositories/prayer_times_repository_impl.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockRemote extends Mock implements PrayerTimesRemoteDataSource {}

class MockGetPrayerTimes extends Mock implements GetPrayerTimes {}

final _day = DateTime(2026, 9, 29);

/// Shaped like the `data` object of Aladhan `timingsByCity`.
Map<String, dynamic> aladhanData() => {
  'timings': {
    'Fajr': '05:21',
    'Sunrise': '06:47',
    'Dhuhr': '12:45',
    'Asr': '16:10',
    'Sunset': '18:43',
    'Maghrib': '18:43 (EET)',
    'Isha': '20:00',
  },
  'date': {
    'hijri': {
      'day': '08',
      'month': {'number': 4, 'ar': 'رَبيع الثاني'},
      'year': '1448',
    },
  },
};

PrayerTimesModel times() => PrayerTimesModel.fromJson(
  aladhanData(),
  date: _day,
  location: PrayerLocation.cairo,
);

DateTime at(int hour, int minute) => DateTime(2026, 9, 29, hour, minute);

void main() {
  group('PrayerTimesModel', () {
    test('parses every prayer as a time on the given day', () {
      final t = times();
      expect(t.timeOf(Prayer.fajr), at(5, 21));
      expect(t.timeOf(Prayer.sunrise), at(6, 47));
      expect(t.timeOf(Prayer.asr), at(16, 10));
      expect(t.timeOf(Prayer.isha), at(20, 0));
    });

    test('ignores the timezone suffix on a time', () {
      expect(times().timeOf(Prayer.maghrib), at(18, 43));
    });

    test('builds the hijri date without a leading zero', () {
      expect(times().hijriDate, '8 رَبيع الثاني 1448 هـ');
    });

    test('keeps the location label', () {
      expect(times().locationLabel, 'القاهرة، مصر');
    });
  });

  group('PrayerTimes.nextPrayer', () {
    test('is Fajr before dawn', () {
      expect(times().nextPrayer(at(3, 0)), NextPrayer(Prayer.fajr, at(5, 21)));
    });

    test('skips sunrise, which is not a prayer', () {
      expect(times().nextPrayer(at(6, 0)).prayer, Prayer.dhuhr);
    });

    test('is the upcoming prayer during the day', () {
      expect(times().nextPrayer(at(16, 9)).prayer, Prayer.asr);
      expect(times().nextPrayer(at(16, 10)).prayer, Prayer.maghrib);
    });

    test("after Isha it is tomorrow's Fajr", () {
      final next = times().nextPrayer(at(21, 0));
      expect(next.prayer, Prayer.fajr);
      expect(next.time, DateTime(2026, 9, 30, 5, 21));
    });
  });

  group('PrayerTimesRemoteDataSourceImpl', () {
    late MockDio dio;
    late PrayerTimesRemoteDataSourceImpl source;

    setUp(() {
      dio = MockDio();
      source = PrayerTimesRemoteDataSourceImpl(dio);
    });

    test('asks for the dated endpoint with city, country and method', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '${PrayerTimesRemoteDataSourceImpl.baseUrl}/timingsByCity/29-09-2026',
          queryParameters: {'city': 'Cairo', 'country': 'Egypt', 'method': 5},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: {'data': aladhanData()},
        ),
      );

      final result = await source.fetch(
        date: _day,
        location: PrayerLocation.cairo,
      );
      expect(result.timeOf(Prayer.dhuhr), at(12, 45));
    });

    test('an unexpected body is a ServerException', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(), data: {}),
      );

      expect(
        source.fetch(date: _day, location: PrayerLocation.cairo),
        throwsA(isA<ServerException>()),
      );
    });

    test('connection problems are a NetworkException', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        source.fetch(date: _day, location: PrayerLocation.cairo),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('PrayerTimesRepositoryImpl', () {
    late MockRemote remote;
    late PrayerTimesRepositoryImpl repository;

    setUp(() {
      remote = MockRemote();
      repository = PrayerTimesRepositoryImpl(remote);
      registerFallbackValue(PrayerLocation.cairo);
    });

    test('caches the times of a day and location', () async {
      when(
        () => remote.fetch(
          date: any(named: 'date'),
          location: any(named: 'location'),
        ),
      ).thenAnswer((_) async => times());

      await repository.getPrayerTimes(
        date: at(9, 0),
        location: PrayerLocation.cairo,
      );
      final second = await repository.getPrayerTimes(
        date: at(22, 0),
        location: PrayerLocation.cairo,
      );

      expect(second.isRight(), isTrue);
      verify(
        () => remote.fetch(
          date: any(named: 'date'),
          location: any(named: 'location'),
        ),
      ).called(1);
    });

    test('maps a network error to NetworkFailure', () async {
      when(
        () => remote.fetch(
          date: any(named: 'date'),
          location: any(named: 'location'),
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.getPrayerTimes(
        date: _day,
        location: PrayerLocation.cairo,
      );
      expect(result.swap().toNullable(), isA<NetworkFailure>());
    });
  });

  group('PrayerTimesCubit', () {
    late MockGetPrayerTimes getPrayerTimes;

    setUp(() {
      getPrayerTimes = MockGetPrayerTimes();
      registerFallbackValue(
        PrayerTimesParams(date: _day, location: PrayerLocation.cairo),
      );
    });

    blocTest<PrayerTimesCubit, PrayerTimesState>(
      'emits loading then the times',
      setUp: () => when(
        () => getPrayerTimes(any()),
      ).thenAnswer((_) async => Right(times())),
      build: () => PrayerTimesCubit(getPrayerTimes),
      act: (cubit) => cubit.load(date: _day),
      expect: () => [
        const PrayerTimesState(status: PrayerTimesStatus.loading),
        PrayerTimesState(status: PrayerTimesStatus.success, times: times()),
      ],
    );

    blocTest<PrayerTimesCubit, PrayerTimesState>(
      'keeps the failure message',
      setUp: () => when(
        () => getPrayerTimes(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline'))),
      build: () => PrayerTimesCubit(getPrayerTimes),
      act: (cubit) => cubit.load(date: _day),
      expect: () => [
        const PrayerTimesState(status: PrayerTimesStatus.loading),
        const PrayerTimesState(
          status: PrayerTimesStatus.failure,
          errorMessage: 'offline',
        ),
      ],
    );
  });
}
