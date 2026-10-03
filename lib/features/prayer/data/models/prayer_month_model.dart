import 'package:manara/features/prayer/domain/entities/hijri_date.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

/// Reads the days of an Aladhan `calendar` response requested with
/// `iso8601=true`, and writes/reads them in a compact form for the offline
/// cache. Malformed input throws a [FormatException] or a [TypeError].
abstract final class PrayerMonthModel {
  static const Map<Prayer, String> _aladhanKeys = {
    Prayer.fajr: 'Fajr',
    Prayer.sunrise: 'Sunrise',
    Prayer.dhuhr: 'Dhuhr',
    Prayer.asr: 'Asr',
    Prayer.maghrib: 'Maghrib',
    Prayer.isha: 'Isha',
  };

  /// `2026-10-02T05:22:00+03:00`.
  static final RegExp _iso = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?(Z|[+-]\d{2}:\d{2})$',
  );

  /// [data] is the response's `data` list, covering [from] to [to]
  /// (inclusive, as `DateTime.utc` dates).
  static PrayerMonth fromAladhan(
    List<dynamic> data, {
    required int year,
    required int month,
    required DateTime from,
    required DateTime to,
    DateTime? fetchedAt,
  }) {
    final days = [
      for (final item in data) _dayFromAladhan(item as Map<String, dynamic>),
    ];
    _checkRange(days, from, to);
    final meta = (data.first as Map<String, dynamic>)['meta'];
    return PrayerMonth(
      year: year,
      month: month,
      timeZone: (meta as Map<String, dynamic>)['timezone'] as String,
      allDays: days,
      fetchedAt: fetchedAt,
    );
  }

  static PrayerDay _dayFromAladhan(Map<String, dynamic> item) {
    final timings = item['timings'] as Map<String, dynamic>;
    final date = item['date'] as Map<String, dynamic>;
    final gregorian = date['gregorian'] as Map<String, dynamic>;
    final hijri = date['hijri'] as Map<String, dynamic>;

    // `DD-MM-YYYY`.
    final g = (gregorian['date'] as String).split('-').map(int.parse).toList();
    if (g.length != 3) throw const FormatException('gregorian date');

    final times = {
      for (final e in _aladhanKeys.entries)
        e.key: parseTime(timings[e.value] as String),
    };
    // Where twilight lasts all night, Aladhan can place Isha after midnight
    // but date it to the same day, i.e. before Maghrib; it belongs to the
    // night that follows.
    final isha = times[Prayer.isha]!;
    if (isha.instant.isBefore(times[Prayer.maghrib]!.instant)) {
      times[Prayer.isha] = PrayerTime(
        isha.instant.add(const Duration(days: 1)),
        isha.utcOffset,
      );
    }

    return PrayerDay(
      date: DateTime.utc(g[2], g[1], g[0]),
      times: times,
      sunset: parseTime(timings['Sunset'] as String),
      hijri: _hijri(
        _int(hijri['day']),
        _int((hijri['month'] as Map<String, dynamic>)['number']),
        _int(hijri['year']),
      ),
    );
  }

  static HijriDate _hijri(int day, int month, int year) {
    if (day < 1 || day > 30 || month < 1 || month > 12) {
      throw FormatException('hijri date', '$day/$month/$year');
    }
    return HijriDate(day: day, month: month, year: year);
  }

  /// Every day from [from] to [to], in order, with its times in order.
  static void _checkRange(List<PrayerDay> days, DateTime from, DateTime to) {
    final expected = to.difference(from).inDays + 1;
    if (days.length != expected) {
      throw FormatException('expected $expected days, got ${days.length}');
    }
    for (var i = 0; i < days.length; i++) {
      final want = DateTime.utc(from.year, from.month, from.day + i);
      if (days[i].date != want) {
        throw FormatException('day $i is ${days[i].date}, expected $want');
      }
      final fajr = days[i].timeOf(Prayer.fajr).local;
      if (DateTime.utc(fajr.year, fajr.month, fajr.day) != want) {
        throw FormatException('Fajr of $want falls on $fajr');
      }
      for (var p = 1; p < Prayer.values.length; p++) {
        final before = days[i].timeOf(Prayer.values[p - 1]).instant;
        if (days[i].timeOf(Prayer.values[p]).instant.isBefore(before)) {
          throw FormatException('times of $want are out of order');
        }
      }
    }
  }

  /// Parses an ISO 8601 time with an offset into the moment and the offset.
  static PrayerTime parseTime(String raw) {
    final m = _iso.firstMatch(raw.trim());
    if (m == null) throw FormatException('time', raw);
    int at(int group) => int.parse(m.group(group)!);

    final zone = m.group(7)!;
    var offset = Duration.zero;
    if (zone != 'Z') {
      final sign = zone.startsWith('-') ? -1 : 1;
      final hm = zone.substring(1).split(':').map(int.parse).toList();
      offset = Duration(hours: hm[0], minutes: hm[1]) * sign;
    }
    final wall = DateTime.utc(
      at(1),
      at(2),
      at(3),
      at(4),
      at(5),
      m.group(6) == null ? 0 : at(6),
    );
    return PrayerTime(wall.subtract(offset), offset);
  }

  static String formatTime(PrayerTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    final l = time.local;
    final o = time.utcOffset;
    final sign = o.isNegative ? '-' : '+';
    final minutes = o.inMinutes.abs();
    return '${l.year.toString().padLeft(4, '0')}-${two(l.month)}-'
        '${two(l.day)}T${two(l.hour)}:${two(l.minute)}:${two(l.second)}'
        '$sign${two(minutes ~/ 60)}:${two(minutes % 60)}';
  }

  static Map<String, dynamic> toJson(PrayerMonth month) => {
    'year': month.year,
    'month': month.month,
    'timeZone': month.timeZone,
    'days': [
      for (final day in month.allDays)
        {
          'date': _date(day.date),
          'times': {
            for (final e in day.times.entries) e.key.name: formatTime(e.value),
          },
          'sunset': formatTime(day.sunset),
          'hijri': [day.hijri.day, day.hijri.month, day.hijri.year],
        },
    ],
  };

  static PrayerMonth fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    return PrayerMonth(
      year: json['year'] as int,
      month: json['month'] as int,
      timeZone: json['timeZone'] as String,
      fetchedAt: fetchedAt,
      allDays: [
        for (final raw in json['days'] as List<dynamic>)
          _dayFromJson(raw as Map<String, dynamic>),
      ],
    );
  }

  static PrayerDay _dayFromJson(Map<String, dynamic> json) {
    final d = (json['date'] as String).split('-').map(int.parse).toList();
    final times = json['times'] as Map<String, dynamic>;
    final hijri = (json['hijri'] as List<dynamic>).cast<int>();
    return PrayerDay(
      date: DateTime.utc(d[0], d[1], d[2]),
      times: {
        for (final p in Prayer.values) p: parseTime(times[p.name] as String),
      },
      sunset: parseTime(json['sunset'] as String),
      hijri: _hijri(hijri[0], hijri[1], hijri[2]),
    );
  }

  /// `yyyy-MM-dd`.
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Aladhan sends some numbers as strings (`"day": "21"`).
  static int _int(Object? value) => switch (value) {
    final int v => v,
    final String v => int.parse(v),
    _ => throw FormatException('number', value),
  };
}
