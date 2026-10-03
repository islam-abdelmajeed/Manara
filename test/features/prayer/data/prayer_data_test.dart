import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/prayer/data/datasources/prayer_local_data_source.dart';
import 'package:manara/features/prayer/data/datasources/prayer_times_remote_data_source.dart';
import 'package:manara/features/prayer/data/models/prayer_month_model.dart';
import 'package:manara/features/prayer/data/repositories/prayer_preferences_repository_impl.dart';
import 'package:manara/features/prayer/data/repositories/prayer_times_repository_impl.dart';
import 'package:manara/features/prayer/domain/entities/hijri_date.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/prayer_fixtures.dart';

class MockDio extends Mock implements Dio {}

class MockRemote extends Mock implements PrayerTimesRemoteDataSource {}

class MockLocal extends Mock implements PrayerLocalDataSource {}

const _settings = PrayerSettings();

const _calendarPath =
    '${PrayerTimesRemoteDataSourceImpl.baseUrl}'
    '/calendar/from/27-09-2026/to/04-11-2026';

String _hm(PrayerTime t) =>
    '${t.local.hour.toString().padLeft(2, '0')}:'
    '${t.local.minute.toString().padLeft(2, '0')}';

PrayerDay _day(PrayerMonth m, int month, int day) =>
    m.allDays.firstWhere((d) => d.date == DateTime.utc(2026, month, day));

void main() {
  group('PrayerMonthModel.fromAladhan', () {
    final october = cairoOctober();

    test('reads every day of the requested range', () {
      expect(october.allDays, hasLength(39));
      expect(october.timeZone, 'Africa/Cairo');
      expect(october.year, 2026);
      expect(october.month, 10);
    });

    test('reads times as moments with the location offset', () {
      final day = _day(october, 10, 2);
      final fajr = day.timeOf(Prayer.fajr);
      expect(fajr.instant, DateTime.utc(2026, 10, 2, 2, 22));
      expect(fajr.utcOffset, const Duration(hours: 3));
      expect(_hm(fajr), '05:22');
      expect(
        [for (final p in Prayer.values) _hm(day.timeOf(p))],
        ['05:22', '06:49', '12:44', '16:08', '18:39', '19:57'],
      );
    });

    test('follows the end of summer time between 29 and 30 Oct', () {
      expect(
        _day(october, 10, 29).timeOf(Prayer.fajr).utcOffset,
        const Duration(hours: 3),
      );
      final fajr = _day(october, 10, 30).timeOf(Prayer.fajr);
      expect(fajr.utcOffset, const Duration(hours: 2));
      expect(_hm(fajr), '04:39');
    });

    test('reads the calculated Hijri date', () {
      expect(
        _day(october, 10, 2).hijri,
        const HijriDate(day: 21, month: 4, year: 1448),
      );
      expect(
        _day(october, 11, 1).hijri,
        const HijriDate(day: 21, month: 5, year: 1448),
      );
    });

    test('moves an Isha dated before Maghrib to the following night', () {
      // Stockholm, June, "middle of the night": Aladhan sends Isha 00:49
      // dated the same day as Maghrib 22:08.
      final month = PrayerMonthModel.fromAladhan(
        aladhanFixture('stockholm_2026_06_20_22_middle_of_night.json')['data']
            as List<dynamic>,
        year: 2026,
        month: 6,
        from: DateTime.utc(2026, 6, 20),
        to: DateTime.utc(2026, 6, 22),
      );
      final day = _day(month, 6, 20);
      final isha = day.timeOf(Prayer.isha);
      expect(_hm(isha), '00:49');
      expect(isha.local.day, 21);
      expect(isha.instant.isAfter(day.timeOf(Prayer.maghrib).instant), isTrue);
    });

    List<dynamic> data() =>
        aladhanFixture('cairo_2026_10.json')['data'] as List<dynamic>;

    PrayerMonth parse(List<dynamic> d) => PrayerMonthModel.fromAladhan(
      d,
      year: 2026,
      month: 10,
      from: DateTime.utc(2026, 9, 27),
      to: DateTime.utc(2026, 11, 4),
    );

    test('rejects a response missing days', () {
      expect(
        () => parse(data()..removeLast()),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects days out of order', () {
      final d = data();
      final first = d.removeAt(0);
      d.insert(1, first);
      expect(() => parse(d), throwsA(isA<FormatException>()));
    });

    test('rejects a time without an offset', () {
      final d = data();
      ((d[0] as Map<String, dynamic>)['timings']
              as Map<String, dynamic>)['Fajr'] =
          '05:22';
      expect(() => parse(d), throwsA(isA<FormatException>()));
    });

    test('rejects an impossible Hijri month', () {
      final d = data();
      (((d[0] as Map<String, dynamic>)['date'] as Map<String, dynamic>)['hijri']
          as Map<String, dynamic>)['month'] = {
        'number': 13,
      };
      expect(() => parse(d), throwsA(isA<FormatException>()));
    });
  });

  group('PrayerMonthModel.parseTime', () {
    test('reads positive, negative and UTC offsets', () {
      final plus = PrayerMonthModel.parseTime('2026-10-02T05:22:00+03:00');
      expect(plus.instant, DateTime.utc(2026, 10, 2, 2, 22));

      final minus = PrayerMonthModel.parseTime('2026-10-02T05:22:00-04:30');
      expect(minus.instant, DateTime.utc(2026, 10, 2, 9, 52));
      expect(minus.utcOffset, const Duration(hours: -4, minutes: -30));
      expect(_hm(minus), '05:22');

      final zulu = PrayerMonthModel.parseTime('2026-10-02T05:22Z');
      expect(zulu.instant, DateTime.utc(2026, 10, 2, 5, 22));
    });

    test('formatTime round-trips', () {
      for (final raw in [
        '2026-10-02T05:22:00+03:00',
        '2026-10-02T05:22:00-04:30',
        '2026-10-02T05:22:00+00:00',
      ]) {
        final t = PrayerMonthModel.parseTime(raw);
        expect(PrayerMonthModel.formatTime(t), raw);
      }
    });
  });

  group('PrayerMonthModel cache JSON', () {
    test('round-trips a month', () {
      final october = cairoOctober(fetchedAt: DateTime.utc(2026, 10, 2));
      final json = jsonDecode(jsonEncode(PrayerMonthModel.toJson(october)));
      final back = PrayerMonthModel.fromJson(
        json as Map<String, dynamic>,
        fetchedAt: october.fetchedAt,
      );
      expect(back, october);
    });
  });

  group('PrayerTimesRemoteDataSourceImpl', () {
    late MockDio dio;
    late PrayerTimesRemoteDataSourceImpl source;

    setUp(() {
      dio = MockDio();
      source = PrayerTimesRemoteDataSourceImpl(dio);
    });

    void answer(Object body) {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: body as Map<String, dynamic>,
        ),
      );
    }

    Future<PrayerMonth> fetch([PrayerSettings settings = _settings]) =>
        source.fetchMonth(
          location: PrayerLocation.cairo,
          settings: settings,
          year: 2026,
          month: 10,
        );

    test('asks for the padded range by coordinates', () async {
      answer(aladhanFixture('cairo_2026_10.json'));

      final month = await fetch();

      expect(month.days, hasLength(31));
      verify(
        () => dio.get<Map<String, dynamic>>(
          _calendarPath,
          queryParameters: {
            'latitude': 30.06263,
            'longitude': 31.24967,
            'method': 5,
            'school': 0,
            'latitudeAdjustmentMethod': 3,
            'iso8601': 'true',
          },
        ),
      ).called(1);
    });

    test('sends the school, rule and minute adjustments', () {
      final query = PrayerTimesRemoteDataSourceImpl.query(
        PrayerLocation.cairo,
        const PrayerSettings(
          school: AsrSchool.hanafi,
          highLatitudeRule: HighLatitudeRule.oneSeventh,
          tune: {Prayer.fajr: 2, Prayer.isha: -3},
        ),
      );
      expect(query['school'], 1);
      expect(query['latitudeAdjustmentMethod'], 2);
      // Imsak,Fajr,Sunrise,Dhuhr,Asr,Maghrib,Sunset,Isha,Midnight.
      expect(query['tune'], '0,2,0,0,0,0,0,-3,0');
    });

    test('an error code in the body is a ServerException', () {
      answer({'code': 400, 'status': 'BAD_REQUEST', 'data': 'x'});
      expect(fetch(), throwsA(isA<ServerException>()));
    });

    test('a malformed body is a ServerException', () {
      answer({
        'code': 200,
        'data': [
          {'timings': 'nope'},
        ],
      });
      expect(fetch(), throwsA(isA<ServerException>()));
    });

    test('connection problems are a NetworkException', () {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(fetch(), throwsA(isA<NetworkException>()));
    });

    test('an HTTP error is a ServerException', () {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(), statusCode: 500),
        ),
      );
      expect(fetch(), throwsA(isA<ServerException>()));
    });
  });

  group('PrayerLocalDataSourceImpl', () {
    late SharedPreferences prefs;
    late PrayerLocalDataSourceImpl local;

    Future<void> init([Map<String, Object> values = const {}]) async {
      SharedPreferences.setMockInitialValues(values);
      prefs = await SharedPreferences.getInstance();
      local = PrayerLocalDataSourceImpl(prefs);
    }

    test('settings default when nothing is stored', () async {
      await init();
      expect(local.readSettings(), const PrayerSettings());
      expect(local.readLocation(), isNull);
    });

    test('settings and location round-trip', () async {
      await init();
      const settings = PrayerSettings(
        method: 3,
        school: AsrSchool.hanafi,
        highLatitudeRule: HighLatitudeRule.middleOfNight,
        hijriOffset: -1,
        tune: {Prayer.dhuhr: 4},
      );
      const alexandria = PrayerLocation(
        id: 361058,
        name: 'الإسكندرية',
        nameEn: 'Alexandria',
        country: 'مصر',
        countryCode: 'EG',
        latitude: 31.20176,
        longitude: 29.91582,
        timeZone: 'Africa/Cairo',
      );
      await local.writeSettings(settings);
      await local.writeLocation(alexandria);

      expect(local.readSettings(), settings);
      expect(local.readLocation(), alexandria);
    });

    test('unreadable or out-of-range values fall back', () async {
      await init({
        'prayer.settings': jsonEncode({
          'school': 'unknown',
          'hijriOffset': 9,
          'tune': {'fajr': -99, 'asr': 'x'},
        }),
        'prayer.location': '{not json',
      });
      final s = local.readSettings();
      expect(s.school, AsrSchool.standard);
      expect(s.hijriOffset, PrayerSettings.maxHijriOffset);
      expect(s.tuneOf(Prayer.fajr), -PrayerSettings.maxTune);
      expect(s.tuneOf(Prayer.asr), 0);
      expect(local.readLocation(), isNull);
    });

    test('a cached month round-trips with its download time', () async {
      await init();
      final october = cairoOctober(fetchedAt: DateTime.utc(2026, 10, 2, 9));
      await local.writeMonth('k', october);
      expect(local.readMonth('k'), october);
      expect(local.readMonth('other'), isNull);
    });

    test('keeps only the most recent months', () async {
      await init();
      final october = cairoOctober(fetchedAt: DateTime.utc(2026, 10, 2));
      for (var i = 0; i < PrayerLocalDataSourceImpl.maxMonths + 2; i++) {
        await local.writeMonth('k$i', october);
      }
      expect(local.readMonth('k0'), isNull);
      expect(local.readMonth('k1'), isNull);
      expect(local.readMonth('k2'), isNotNull);
      expect(local.readMonth('k7'), isNotNull);
      expect(
        prefs.getKeys().where((k) => k.startsWith('prayer.month.')),
        hasLength(PrayerLocalDataSourceImpl.maxMonths),
      );
    });

    test('a corrupt cached month reads as missing', () async {
      await init({'prayer.month.k': '{"fetchedAt": "2026-10-02", "month": 1}'});
      expect(local.readMonth('k'), isNull);
    });
  });

  group('PrayerTimesRepositoryImpl', () {
    late MockRemote remote;
    late PrayerLocalDataSourceImpl local;
    late DateTime now;
    late PrayerTimesRepositoryImpl repository;

    setUpAll(() {
      registerFallbackValue(PrayerLocation.cairo);
      registerFallbackValue(_settings);
      registerFallbackValue(cairoOctober());
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      local = PrayerLocalDataSourceImpl(await SharedPreferences.getInstance());
      remote = MockRemote();
      now = DateTime.utc(2026, 10, 2, 9);
      repository = PrayerTimesRepositoryImpl(remote, local, clock: () => now);
    });

    void remoteAnswers(Future<PrayerMonth> Function() answer) {
      when(
        () => remote.fetchMonth(
          location: any(named: 'location'),
          settings: any(named: 'settings'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) => answer());
    }

    void verifyFetches(int times) => verify(
      () => remote.fetchMonth(
        location: any(named: 'location'),
        settings: any(named: 'settings'),
        year: any(named: 'year'),
        month: any(named: 'month'),
      ),
    ).called(times);

    Future<PrayerMonth> get() async {
      final result = await repository.getMonth(
        location: PrayerLocation.cairo,
        settings: _settings,
        year: 2026,
        month: 10,
      );
      return result.getOrElse((f) => throw StateError(f.message));
    }

    String key() => PrayerTimesRepositoryImpl.cacheKey(
      PrayerLocation.cairo,
      _settings,
      2026,
      10,
    );

    test('downloads once, stamps and stores the month', () async {
      remoteAnswers(() async => cairoOctober());

      final first = await get();
      final second = await get();

      expect(first.fetchedAt, now);
      expect(second, first);
      expect(local.readMonth(key()), first);
      verifyFetches(1);
    });

    test('shares a request in flight', () async {
      final completer = Completer<PrayerMonth>();
      remoteAnswers(() => completer.future);

      final a = get();
      final b = get();
      completer.complete(cairoOctober());

      expect(await a, await b);
      verifyFetches(1);
    });

    test('uses a fresh stored month without the network', () async {
      await local.writeMonth(
        key(),
        cairoOctober(fetchedAt: now.subtract(const Duration(hours: 23))),
      );
      remoteAnswers(() async => throw const NetworkException());

      final month = await get();

      expect(month.days, hasLength(31));
      verifyNever(
        () => remote.fetchMonth(
          location: any(named: 'location'),
          settings: any(named: 'settings'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      );
    });

    test('refreshes a stored month older than a day', () async {
      await local.writeMonth(
        key(),
        cairoOctober(fetchedAt: now.subtract(const Duration(hours: 25))),
      );
      remoteAnswers(() async => cairoOctober());

      final month = await get();

      expect(month.fetchedAt, now);
      verifyFetches(1);
    });

    test('a stored month from the future is refreshed', () async {
      await local.writeMonth(
        key(),
        cairoOctober(fetchedAt: now.add(const Duration(days: 3))),
      );
      remoteAnswers(() async => cairoOctober());

      expect((await get()).fetchedAt, now);
    });

    test('offline, falls back to an old stored month', () async {
      final old = now.subtract(const Duration(days: 5));
      await local.writeMonth(key(), cairoOctober(fetchedAt: old));
      remoteAnswers(() async => throw const NetworkException());

      final month = await get();

      expect(month.fetchedAt, old);
    });

    test('a server error also falls back to an old stored month', () async {
      final old = now.subtract(const Duration(days: 5));
      await local.writeMonth(key(), cairoOctober(fetchedAt: old));
      remoteAnswers(() async => throw const ServerException(message: 'down'));

      expect((await get()).fetchedAt, old);
    });

    test('offline with nothing stored is a NetworkFailure', () async {
      remoteAnswers(() async => throw const NetworkException());

      final result = await repository.getMonth(
        location: PrayerLocation.cairo,
        settings: _settings,
        year: 2026,
        month: 10,
      );

      expect(result.swap().toNullable(), isA<NetworkFailure>());
    });

    test('a server error with nothing stored is a ServerFailure', () async {
      remoteAnswers(() async => throw const ServerException(message: 'down'));

      final result = await repository.getMonth(
        location: PrayerLocation.cairo,
        settings: _settings,
        year: 2026,
        month: 10,
      );

      expect(result.swap().toNullable(), const ServerFailure('down'));
    });

    test('a failure is forgotten so the next call tries again', () async {
      var calls = 0;
      remoteAnswers(() async {
        if (calls++ == 0) throw const NetworkException();
        return cairoOctober();
      });

      final failed = await repository.getMonth(
        location: PrayerLocation.cairo,
        settings: _settings,
        year: 2026,
        month: 10,
      );
      expect(failed.isLeft(), isTrue);
      expect((await get()).days, hasLength(31));
    });

    test('a failed cache write still returns the times', () async {
      final mockLocal = MockLocal();
      when(() => mockLocal.readMonth(any())).thenReturn(null);
      when(
        () => mockLocal.writeMonth(any(), any()),
      ).thenThrow(const CacheException());
      repository = PrayerTimesRepositoryImpl(
        remote,
        mockLocal,
        clock: () => now,
      );
      remoteAnswers(() async => cairoOctober());

      expect((await get()).days, hasLength(31));
    });

    test('other settings are a different month', () async {
      remoteAnswers(() async => cairoOctober());

      await get();
      await repository.getMonth(
        location: PrayerLocation.cairo,
        settings: const PrayerSettings(school: AsrSchool.hanafi),
        year: 2026,
        month: 10,
      );

      verifyFetches(2);
    });
  });

  group('PrayerPreferencesRepositoryImpl', () {
    test('defaults to Cairo and saves a choice', () async {
      SharedPreferences.setMockInitialValues({});
      final local = PrayerLocalDataSourceImpl(
        await SharedPreferences.getInstance(),
      );
      final repository = PrayerPreferencesRepositoryImpl(local);

      expect(
        (await repository.getLocation()).toNullable(),
        PrayerLocation.cairo,
      );
      const hanafi = PrayerSettings(school: AsrSchool.hanafi);
      await repository.saveSettings(hanafi);
      expect((await repository.getSettings()).toNullable(), hanafi);
    });
  });
}
