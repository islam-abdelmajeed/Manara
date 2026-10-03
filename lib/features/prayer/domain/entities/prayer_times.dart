import 'package:equatable/equatable.dart';
import 'package:manara/features/prayer/domain/entities/hijri_date.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';

enum Prayer {
  fajr('الفجر'),
  sunrise('الشروق'),
  dhuhr('الظهر'),
  asr('العصر'),
  maghrib('المغرب'),
  isha('العشاء');

  const Prayer(this.label);

  final String label;

  /// Sunrise is listed with the prayers but is not one.
  bool get isPrayer => this != Prayer.sunrise;
}

/// A moment together with the location's UTC offset at that moment, so it
/// can be shown in the location's time whatever the device's time zone.
class PrayerTime extends Equatable {
  const PrayerTime(this.instant, this.utcOffset);

  /// The moment, in UTC.
  final DateTime instant;

  /// Offset of the location's clock at [instant] (changes with DST).
  final Duration utcOffset;

  /// Wall-clock time at the location. A UTC [DateTime] whose fields read as
  /// the location's local date and time; use it for display only.
  DateTime get local => instant.toUtc().add(utcOffset);

  @override
  List<Object?> get props => [instant, utcOffset];
}

/// Times of one calendar day at one location.
class PrayerDay extends Equatable {
  const PrayerDay({
    required this.date,
    required this.times,
    required this.sunset,
    required this.hijri,
  });

  /// The location's calendar date, as `DateTime.utc(year, month, day)`.
  final DateTime date;

  final Map<Prayer, PrayerTime> times;

  /// Sunset, which is not Maghrib in every method (e.g. Tehran, Jafari).
  final PrayerTime sunset;

  final HijriDate hijri;

  PrayerTime timeOf(Prayer prayer) => times[prayer]!;

  /// The location's offset on this day.
  Duration get utcOffset => timeOf(Prayer.fajr).utcOffset;

  /// The moment this day begins at the location (local midnight).
  DateTime get start => date.subtract(utcOffset);

  /// From sunrise to sunset.
  Duration get dayLength =>
      sunset.instant.difference(timeOf(Prayer.sunrise).instant);

  PrayerDay copyWith({HijriDate? hijri}) => PrayerDay(
    date: date,
    times: times,
    sunset: sunset,
    hijri: hijri ?? this.hijri,
  );

  @override
  List<Object?> get props => [date, times, sunset, hijri];
}

/// The days of one Gregorian month, padded with a few days on each side so
/// tomorrow's Fajr and shifted Hijri dates are known at the month's edges.
class PrayerMonth extends Equatable {
  const PrayerMonth({
    required this.year,
    required this.month,
    required this.timeZone,
    required this.allDays,
    this.fetchedAt,
  });

  /// Days fetched before and after the month.
  static const int padding = 4;

  final int year;
  final int month;

  /// IANA zone Aladhan used, e.g. `Africa/Cairo`.
  final String timeZone;

  /// The month's days plus the padding, in order.
  final List<PrayerDay> allDays;

  /// When the times were downloaded; older than a day means they came from
  /// the offline cache because the network failed.
  final DateTime? fetchedAt;

  /// Only the days of [month].
  List<PrayerDay> get days => [
    for (final d in allDays)
      if (d.date.year == year && d.date.month == month) d,
  ];

  /// The day that contains [now] at the location, if it was loaded.
  PrayerDay? dayAt(DateTime now) {
    final instant = now.toUtc();
    PrayerDay? found;
    for (final day in allDays) {
      if (day.start.isAfter(instant)) break;
      found = day;
    }
    // Past the last loaded day's end means it is not loaded.
    if (found == allDays.lastOrNull &&
        found != null &&
        !instant.isBefore(found.start.add(const Duration(days: 1)))) {
      return null;
    }
    return found;
  }

  /// The day after [day], if it was loaded.
  PrayerDay? dayAfter(PrayerDay day) {
    final i = allDays.indexOf(day);
    return i < 0 || i + 1 >= allDays.length ? null : allDays[i + 1];
  }

  /// Each day takes the Hijri date calculated for the day [offset] days
  /// away; days at the edges without one are dropped.
  PrayerMonth withHijriOffset(int offset) {
    if (offset == 0) return this;
    return PrayerMonth(
      year: year,
      month: month,
      timeZone: timeZone,
      fetchedAt: fetchedAt,
      allDays: [
        for (var i = 0; i < allDays.length; i++)
          if (i + offset >= 0 && i + offset < allDays.length)
            allDays[i].copyWith(hijri: allDays[i + offset].hijri),
      ],
    );
  }

  @override
  List<Object?> get props => [year, month, timeZone, allDays, fetchedAt];
}

class NextPrayer extends Equatable {
  const NextPrayer(this.prayer, this.time);

  final Prayer prayer;
  final PrayerTime time;

  @override
  List<Object?> get props => [prayer, time];
}

/// Today's times at a location, with tomorrow's for the night after Isha.
class PrayerTimes extends Equatable {
  const PrayerTimes({
    required this.location,
    required this.today,
    required this.tomorrow,
    this.fetchedAt,
  });

  final PrayerLocation location;
  final PrayerDay today;
  final PrayerDay tomorrow;

  /// When the times were downloaded (see [PrayerMonth.fetchedAt]).
  final DateTime? fetchedAt;

  PrayerTime timeOf(Prayer prayer) => today.timeOf(prayer);

  /// e.g. `21 ربيع الثاني 1448 هـ`.
  String get hijriDate => today.hijri.label;

  /// e.g. `القاهرة، مصر`.
  String get locationLabel => location.label;

  /// The first prayer after [now]; after Isha, tomorrow's Fajr.
  NextPrayer nextPrayer(DateTime now) {
    for (final prayer in Prayer.values) {
      if (!prayer.isPrayer) continue;
      final time = timeOf(prayer);
      if (time.instant.isAfter(now)) return NextPrayer(prayer, time);
    }
    return NextPrayer(Prayer.fajr, tomorrow.timeOf(Prayer.fajr));
  }

  @override
  List<Object?> get props => [location, today, tomorrow, fetchedAt];
}
