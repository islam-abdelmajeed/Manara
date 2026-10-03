import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/prayer/domain/entities/hijri_date.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/entities/qibla.dart';

import '../../../helpers/prayer_fixtures.dart';

void main() {
  String hm(PrayerTime t) =>
      '${t.local.hour.toString().padLeft(2, '0')}:'
      '${t.local.minute.toString().padLeft(2, '0')}';

  group('PrayerTimes.nextPrayer', () {
    // 2 Oct 2026, Cairo: Fajr 05:22, Sunrise 06:49, Dhuhr 12:44,
    // Asr 16:08, Maghrib 18:39, Isha 19:57 (UTC+3).
    final times = cairoTimes(10, 2);

    test('is Fajr before dawn', () {
      final next = times.nextPrayer(cairo(10, 2, 3));
      expect(next.prayer, Prayer.fajr);
      expect(hm(next.time), '05:22');
      expect(next.time.local.day, 2);
    });

    test('skips sunrise, which is not a prayer', () {
      expect(times.nextPrayer(cairo(10, 2, 6)).prayer, Prayer.dhuhr);
    });

    test('is the upcoming prayer between prayers', () {
      expect(times.nextPrayer(cairo(10, 2, 16, 7)).prayer, Prayer.asr);
      // At the exact minute the prayer has come; the next one is Maghrib.
      expect(times.nextPrayer(cairo(10, 2, 16, 8)).prayer, Prayer.maghrib);
    });

    test("after Isha it is tomorrow's own Fajr", () {
      final next = times.nextPrayer(cairo(10, 2, 21));
      expect(next.prayer, Prayer.fajr);
      expect(next.time.local.day, 3);
      // 3 Oct's own time, not today's 05:22 moved a day ahead.
      expect(hm(next.time), '05:23');
      expect(next.time.instant, cairo(10, 3, 5, 23));
    });

    test('counts down across midnight to the next Fajr', () {
      final now = cairo(10, 2, 23, 59, 59);
      final left = times.nextPrayer(now).time.instant.difference(now);
      expect(left, const Duration(hours: 5, minutes: 23, seconds: 1));
    });

    test('after Isha on the last night of summer time, Fajr is in UTC+2', () {
      // 29 Oct: Isha 19:29 (UTC+3); 30 Oct: Fajr 04:39 (UTC+2).
      final night = cairoTimes(10, 29);
      final now = cairo(10, 29, 20);
      final next = night.nextPrayer(now);
      expect(next.prayer, Prayer.fajr);
      expect(hm(next.time), '04:39');
      expect(next.time.utcOffset, const Duration(hours: 2));
      expect(
        next.time.instant.difference(now),
        const Duration(hours: 9, minutes: 39),
      );
    });

    test('does not depend on the device time zone', () {
      final utc = cairo(10, 2, 13);
      expect(times.nextPrayer(utc), times.nextPrayer(utc.toLocal()));
    });
  });

  group('PrayerMonth', () {
    final october = cairoOctober();

    test('days are only those of the month; padding is kept apart', () {
      expect(october.allDays, hasLength(39));
      expect(october.days, hasLength(31));
      expect(october.days.first.date, DateTime.utc(2026, 10));
      expect(october.days.last.date, DateTime.utc(2026, 10, 31));
    });

    test('dayAt follows the location calendar, not UTC', () {
      expect(october.dayAt(cairo(10, 1, 23, 30))!.date, DateTime.utc(2026, 10));
      // 00:30 in Cairo is 21:30 UTC the day before.
      expect(
        october.dayAt(cairo(10, 2, 0, 30))!.date,
        DateTime.utc(2026, 10, 2),
      );
    });

    test('the repeated hour at the end of summer time stays on 29 Oct', () {
      // Clocks go from 24:00 (UTC+3) back to 23:00 (UTC+2).
      expect(
        october.dayAt(DateTime.utc(2026, 10, 29, 20, 30))!.date,
        DateTime.utc(2026, 10, 29),
      );
      expect(
        october.dayAt(DateTime.utc(2026, 10, 29, 21, 30))!.date,
        DateTime.utc(2026, 10, 29),
      );
      expect(
        october.dayAt(DateTime.utc(2026, 10, 29, 22))!.date,
        DateTime.utc(2026, 10, 30),
      );
    });

    test('dayAt is null outside the loaded days', () {
      expect(october.dayAt(DateTime.utc(2026, 9, 26, 12)), isNull);
      expect(october.dayAt(DateTime.utc(2026, 11, 5, 12)), isNull);
    });

    test('dayAfter crosses into the padding', () {
      final last = october.days.last;
      expect(october.dayAfter(last)!.date, DateTime.utc(2026, 11));
      expect(october.dayAfter(october.allDays.last), isNull);
    });

    test('the December month crosses the year', () {
      final december = cairoDecember();
      final last = december.days.last;
      expect(december.dayAfter(last)!.date, DateTime.utc(2027));
    });

    test('a Hijri offset takes the date of the day that many days away', () {
      HijriDate hijriOn(PrayerMonth m, int day) => m.allDays
          .firstWhere((d) => d.date == DateTime.utc(2026, 10, day))
          .hijri;

      // Calculated: 2 Oct 2026 = 21 Rabi al-Thani 1448.
      expect(
        hijriOn(october, 2),
        const HijriDate(day: 21, month: 4, year: 1448),
      );
      expect(
        hijriOn(october.withHijriOffset(1), 2),
        const HijriDate(day: 22, month: 4, year: 1448),
      );
      expect(
        hijriOn(october.withHijriOffset(-2), 2),
        const HijriDate(day: 19, month: 4, year: 1448),
      );
    });

    test(
      'a Hijri offset keeps the times and drops edge days without a date',
      () {
        final shifted = october.withHijriOffset(2);
        expect(shifted.allDays, hasLength(37));
        expect(shifted.days, hasLength(31));
        expect(shifted.days.first.times, october.days.first.times);
        expect(october.withHijriOffset(0), same(october));
      },
    );
  });

  group('HijriDate', () {
    test('labels use the names without diacritics', () {
      const date = HijriDate(day: 21, month: 4, year: 1448);
      expect(date.label, '21 ربيع الثاني 1448 هـ');
      expect(date.shortLabel, '21/4');
      expect(HijriDate.monthNames, hasLength(12));
    });
  });

  group('Qibla', () {
    test('matches the Aladhan Qibla API for Cairo', () {
      // GET /v1/qibla/30.06263/31.24967 → 136.24852526210466.
      final qibla = Qibla.from(30.06263, 31.24967);
      expect(qibla.bearing, closeTo(136.248525, 0.0005));
      expect(qibla.distanceKm, closeTo(1287.75, 0.01));
      expect(qibla.directionLabel, 'ج ق');
    });

    test('matches the API elsewhere and wraps to [0, 360)', () {
      // /v1/qibla for London, Jakarta and New York.
      expect(
        Qibla.from(51.50853, -0.12574).bearing,
        closeTo(118.990574, 0.0005),
      );
      final jakarta = Qibla.from(-6.21462, 106.84513);
      expect(jakarta.bearing, closeTo(295.153654, 0.0005));
      expect(jakarta.directionLabel, 'ش غ');
      expect(
        Qibla.from(40.71427, -74.00597).bearing,
        closeTo(58.481673, 0.0005),
      );
    });

    test('is zero distance at the Kaaba', () {
      final qibla = Qibla.from(Qibla.kaabaLatitude, Qibla.kaabaLongitude);
      expect(qibla.distanceKm, closeTo(0, 1e-9));
    });
  });

  group('PrayerSettings', () {
    test('defaults: Egyptian method, standard Asr, angle-based', () {
      const s = PrayerSettings();
      expect(s.method, 5);
      expect(s.school, AsrSchool.standard);
      expect(s.highLatitudeRule, HighLatitudeRule.angleBased);
      expect(s.hijriOffset, 0);
      expect(s.tuneOf(Prayer.fajr), 0);
    });

    test('the calculation key ignores the Hijri offset', () {
      const s = PrayerSettings();
      expect(s.copyWith(hijriOffset: 1).calculationKey, s.calculationKey);
      expect(
        s.copyWith(tune: {Prayer.isha: 2}).calculationKey,
        isNot(s.calculationKey),
      );
      expect(
        s.copyWith(school: AsrSchool.hanafi).calculationKey,
        isNot(s.calculationKey),
      );
    });

    test('a zero tune equals no tune', () {
      expect(
        const PrayerSettings(tune: {Prayer.fajr: 0}),
        const PrayerSettings(),
      );
    });
  });
}
