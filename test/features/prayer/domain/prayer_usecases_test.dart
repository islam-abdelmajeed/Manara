import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/prayer/domain/entities/hijri_date.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/repositories/prayer_times_repository.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/prayer_fixtures.dart';

class MockRepository extends Mock implements PrayerTimesRepository {}

void main() {
  late MockRepository repository;
  late GetPrayerTimes getTimes;

  setUpAll(() {
    registerFallbackValue(PrayerLocation.cairo);
    registerFallbackValue(const PrayerSettings());
  });

  setUp(() {
    repository = MockRepository();
    getTimes = GetPrayerTimes(GetPrayerMonth(repository));
    when(
      () => repository.getMonth(
        location: any(named: 'location'),
        settings: any(named: 'settings'),
        year: 2026,
        month: 10,
      ),
    ).thenAnswer((_) async => Right(cairoOctober()));
    when(
      () => repository.getMonth(
        location: any(named: 'location'),
        settings: any(named: 'settings'),
        year: 2026,
        month: 12,
      ),
    ).thenAnswer((_) async => Right(cairoDecember()));
  });

  Future<PrayerTimes> timesAt(
    DateTime now, [
    PrayerSettings settings = const PrayerSettings(),
  ]) async {
    final result = await getTimes(
      PrayerTimesParams(
        now: now,
        location: PrayerLocation.cairo,
        settings: settings,
      ),
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  group('GetPrayerTimes', () {
    test("gives the location's today and tomorrow", () async {
      final times = await timesAt(cairo(10, 2, 12));
      expect(times.today.date, DateTime.utc(2026, 10, 2));
      expect(times.tomorrow.date, DateTime.utc(2026, 10, 3));
      expect(times.location, PrayerLocation.cairo);
    });

    test(
      'after midnight in Cairo it is the next day, from the padding',
      () async {
        // 00:30 on 1 Nov in Cairo is still 31 Oct in UTC.
        final times = await timesAt(cairo(11, 1, 0, 30));
        expect(times.today.date, DateTime.utc(2026, 11));
        expect(times.tomorrow.date, DateTime.utc(2026, 11, 2));
        verify(
          () => repository.getMonth(
            location: any(named: 'location'),
            settings: any(named: 'settings'),
            year: 2026,
            month: 10,
          ),
        ).called(1);
      },
    );

    test('crosses into the new year', () async {
      final times = await timesAt(DateTime.utc(2026, 12, 31, 22, 30));
      expect(times.today.date, DateTime.utc(2027));
      expect(times.tomorrow.date, DateTime.utc(2027, 1, 2));
    });

    test('applies the Hijri offset', () async {
      final times = await timesAt(
        cairo(10, 2, 12),
        const PrayerSettings(hijriOffset: 1),
      );
      expect(times.today.hijri, const HijriDate(day: 22, month: 4, year: 1448));
      expect(times.hijriDate, '22 ربيع الثاني 1448 هـ');
    });

    test('passes a failure through', () async {
      when(
        () => repository.getMonth(
          location: any(named: 'location'),
          settings: any(named: 'settings'),
          year: any(named: 'year'),
          month: any(named: 'month'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await getTimes(
        PrayerTimesParams(
          now: cairo(10, 2, 12),
          location: PrayerLocation.cairo,
          settings: const PrayerSettings(),
        ),
      );
      expect(result.swap().toNullable(), const NetworkFailure());
    });

    test('a month that does not contain today is a failure', () async {
      when(
        () => repository.getMonth(
          location: any(named: 'location'),
          settings: any(named: 'settings'),
          year: 2026,
          month: 12,
        ),
      ).thenAnswer((_) async => Right(cairoOctober()));

      final result = await getTimes(
        PrayerTimesParams(
          now: DateTime.utc(2026, 12, 15, 12),
          location: PrayerLocation.cairo,
          settings: const PrayerSettings(),
        ),
      );
      expect(result.swap().toNullable(), isA<ServerFailure>());
    });
  });

  group('GetPrayerMonth', () {
    test(
      'asks for the month with the settings and shifts the Hijri date',
      () async {
        final result = await GetPrayerMonth(repository)(
          const PrayerMonthParams(
            location: PrayerLocation.cairo,
            settings: PrayerSettings(hijriOffset: -1),
            year: 2026,
            month: 10,
          ),
        );
        final month = result.getOrElse((f) => throw StateError(f.message));
        expect(
          month.days.firstWhere((d) => d.date.day == 2).hijri,
          const HijriDate(day: 20, month: 4, year: 1448),
        );
      },
    );
  });

  group('GetUpcomingPrayerDays', () {
    late GetUpcomingPrayerDays upcoming;

    void stubNovember(Either<Failure, PrayerMonth> result) => when(
      () => repository.getMonth(
        location: any(named: 'location'),
        settings: any(named: 'settings'),
        year: 2026,
        month: 11,
      ),
    ).thenAnswer((_) async => result);

    setUp(() {
      upcoming = GetUpcomingPrayerDays(GetPrayerMonth(repository));
      stubNovember(Right(cairoNovember()));
    });

    Future<Either<Failure, List<PrayerDay>>> daysAt(DateTime now) => upcoming(
      UpcomingDaysParams(
        now: now,
        location: PrayerLocation.cairo,
        settings: const PrayerSettings(),
        count: 10,
      ),
    );

    List<DateTime> dates(Either<Failure, List<PrayerDay>> result) => result
        .getOrElse((f) => throw StateError(f.message))
        .map((d) => d.date)
        .toList();

    List<DateTime> from(int month, int day, int count) => [
      for (var i = 0; i < count; i++) DateTime.utc(2026, month, day + i),
    ];

    test('mid-month: today and the next nine days, one request', () async {
      expect(dates(await daysAt(cairo(10, 2, 13))), from(10, 2, 10));
      verifyNever(
        () => repository.getMonth(
          location: any(named: 'location'),
          settings: any(named: 'settings'),
          year: 2026,
          month: 11,
        ),
      );
    });

    test('runs on into the next month without repeating a day', () async {
      // October's padding ends on 4 Nov; 5–8 Nov come from November.
      final result = await daysAt(cairo(10, 30, 13));
      expect(dates(result), from(10, 30, 10));
      final days = result.getOrElse((_) => []);
      // The shared days are October's own (Aladhan's Asr on 31 Oct differs
      // by a minute between the two requests).
      expect(days[1], cairoOctober().allDays.firstWhere((d) => d == days[1]));
    });

    test('without the next month, the days there are', () async {
      stubNovember(const Left(NetworkFailure()));
      expect(dates(await daysAt(cairo(10, 30, 13))), from(10, 30, 6));
    });

    test("this month's failure is the result", () async {
      when(
        () => repository.getMonth(
          location: any(named: 'location'),
          settings: any(named: 'settings'),
          year: 2026,
          month: 10,
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      expect((await daysAt(cairo(10, 2, 13))).isLeft(), isTrue);
    });
  });
}
