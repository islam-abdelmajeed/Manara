import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/prayer/domain/entities/hijri_date.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';

PrayerTime _at(int hour, int minute) => PrayerTime(
  DateTime.utc(2026, 10, 2, hour, minute).subtract(const Duration(hours: 3)),
  const Duration(hours: 3),
);

void main() {
  group('PrayerFormat', () {
    test('12-hour clock with ص / م, in the location time', () {
      expect(PrayerFormat.clock(_at(5, 22)), '05:22');
      expect(PrayerFormat.clockWithPeriod(_at(5, 22)), '05:22 ص');
      expect(PrayerFormat.clockWithPeriod(_at(12, 44)), '12:44 م');
      expect(PrayerFormat.clockWithPeriod(_at(0, 5)), '12:05 ص');
      expect(PrayerFormat.clockWithPeriod(_at(19, 57)), '07:57 م');
    });

    test('countdown parts are two digits and never negative', () {
      expect(
        PrayerFormat.countdown(
          const Duration(hours: 3, minutes: 8, seconds: 5),
        ),
        ('03', '08', '05'),
      );
      expect(PrayerFormat.countdown(const Duration(seconds: -4)), (
        '00',
        '00',
        '00',
      ));
    });

    test('the full date names the weekday and both calendars', () {
      expect(
        PrayerFormat.fullDate(
          DateTime.utc(2026, 8, 31),
          const HijriDate(day: 18, month: 3, year: 1448),
        ),
        'الاثنين، 31 أغسطس 2026 · 18 ربيع الأول 1448 هـ',
      );
    });

    test('durations follow Arabic number agreement', () {
      Duration hm(int h, int m) => Duration(hours: h, minutes: m);
      expect(PrayerFormat.duration(hm(13, 14)), '13 ساعة 14 دقيقة');
      expect(PrayerFormat.duration(hm(10, 3)), '10 ساعات 3 دقائق');
      expect(PrayerFormat.duration(hm(11, 1)), '11 ساعة دقيقة واحدة');
      expect(PrayerFormat.duration(hm(1, 0)), 'ساعة واحدة');
      expect(PrayerFormat.duration(hm(2, 2)), 'ساعتان دقيقتان');
      expect(PrayerFormat.duration(hm(12, 0)), '12 ساعة');
    });

    test('kilometres are rounded with thousands separators', () {
      expect(PrayerFormat.km(1287.75), '1,288 km');
      expect(PrayerFormat.km(7.11), '7 km');
      expect(PrayerFormat.km(12345.4), '12,345 km');
    });

    test('degrees keep the sign after the number in Arabic text', () {
      expect(PrayerFormat.degrees(136.2485), '136.2°‎');
    });

    test('coordinates have four decimals', () {
      expect(PrayerFormat.coordinates(30.06263, 31.24967), '30.0626, 31.2497');
    });
  });
}
