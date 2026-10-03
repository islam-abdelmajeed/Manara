import 'dart:convert';
import 'dart:io';

import 'package:manara/features/prayer/data/models/prayer_month_model.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

/// A real Aladhan `calendar/from/…/to/…` response (method 5, iso8601),
/// trimmed to the fields the app reads. See test/fixtures/aladhan.
Map<String, dynamic> aladhanFixture(String name) =>
    jsonDecode(File('test/fixtures/aladhan/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Cairo (GeoNames coordinates), 27 Sep – 4 Nov 2026. Covers the end of
/// Egyptian summer time: 29 Oct is UTC+3, 30 Oct is UTC+2.
PrayerMonth cairoOctober({DateTime? fetchedAt}) => PrayerMonthModel.fromAladhan(
  aladhanFixture('cairo_2026_10.json')['data'] as List<dynamic>,
  year: 2026,
  month: 10,
  from: DateTime.utc(2026, 9, 27),
  to: DateTime.utc(2026, 11, 4),
  fetchedAt: fetchedAt,
);

/// Cairo, 27 Oct – 4 Dec 2026. Fetched separately from [cairoOctober]: on
/// two of the shared days Aladhan's Asr differs by a minute (its rounding
/// depends on the requested range).
PrayerMonth cairoNovember({DateTime? fetchedAt}) =>
    PrayerMonthModel.fromAladhan(
      aladhanFixture('cairo_2026_11.json')['data'] as List<dynamic>,
      year: 2026,
      month: 11,
      from: DateTime.utc(2026, 10, 27),
      to: DateTime.utc(2026, 12, 4),
      fetchedAt: fetchedAt,
    );

/// Cairo, 27 Nov 2026 – 4 Jan 2027 (UTC+2 throughout).
PrayerMonth cairoDecember({DateTime? fetchedAt}) =>
    PrayerMonthModel.fromAladhan(
      aladhanFixture('cairo_2026_12.json')['data'] as List<dynamic>,
      year: 2026,
      month: 12,
      from: DateTime.utc(2026, 11, 27),
      to: DateTime.utc(2027, 1, 4),
      fetchedAt: fetchedAt,
    );

/// The moment Cairo's clock reads the given time in 2026 (UTC+3 from
/// 24 Apr to 29 Oct, UTC+2 otherwise; not for the repeated hour).
DateTime cairo(int month, int day, int hour, [int minute = 0, int second = 0]) {
  final summer =
      DateTime.utc(2026, month, day).isAfter(DateTime.utc(2026, 4, 23)) &&
      DateTime.utc(2026, month, day).isBefore(DateTime.utc(2026, 10, 30));
  return DateTime.utc(
    2026,
    month,
    day,
    hour,
    minute,
    second,
  ).subtract(Duration(hours: summer ? 3 : 2));
}

/// Today and tomorrow from [cairoOctober] for the Cairo date [month]/[day].
PrayerTimes cairoTimes(int month, int day) {
  final october = cairoOctober();
  final today = october.allDays.firstWhere(
    (d) => d.date == DateTime.utc(2026, month, day),
  );
  return PrayerTimes(
    location: PrayerLocation.cairo,
    today: today,
    tomorrow: october.dayAfter(today)!,
  );
}
