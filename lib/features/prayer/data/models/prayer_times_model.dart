import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

/// Parses the `data` object of the Aladhan `timingsByCity` response.
class PrayerTimesModel extends PrayerTimes {
  const PrayerTimesModel({
    required super.date,
    required super.times,
    required super.hijriDate,
    required super.locationLabel,
  });

  static const Map<Prayer, String> _keys = {
    Prayer.fajr: 'Fajr',
    Prayer.sunrise: 'Sunrise',
    Prayer.dhuhr: 'Dhuhr',
    Prayer.asr: 'Asr',
    Prayer.maghrib: 'Maghrib',
    Prayer.isha: 'Isha',
  };

  factory PrayerTimesModel.fromJson(
    Map<String, dynamic> data, {
    required DateTime date,
    required PrayerLocation location,
  }) {
    final timings = data['timings'] as Map<String, dynamic>;
    final day = DateTime(date.year, date.month, date.day);

    final times = {
      for (final entry in _keys.entries)
        entry.key: _at(day, timings[entry.value] as String),
    };

    final hijri =
        (data['date'] as Map<String, dynamic>)['hijri'] as Map<String, dynamic>;
    final month = (hijri['month'] as Map<String, dynamic>)['ar'] as String;
    final hijriDate =
        '${int.parse(hijri['day'] as String)} $month ${hijri['year']} هـ';

    return PrayerTimesModel(
      date: day,
      times: times,
      hijriDate: hijriDate,
      locationLabel: location.label,
    );
  }

  /// Times look like `05:21` or `05:21 (EET)`.
  static DateTime _at(DateTime day, String raw) {
    final hm = raw.split(' ').first.split(':');
    return day.add(
      Duration(hours: int.parse(hm[0]), minutes: int.parse(hm[1])),
    );
  }
}
