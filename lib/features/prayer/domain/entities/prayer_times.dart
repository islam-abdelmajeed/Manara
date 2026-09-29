import 'package:equatable/equatable.dart';

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

class NextPrayer extends Equatable {
  const NextPrayer(this.prayer, this.time);

  final Prayer prayer;
  final DateTime time;

  @override
  List<Object?> get props => [prayer, time];
}

/// Prayer times of one day for one location.
class PrayerTimes extends Equatable {
  const PrayerTimes({
    required this.date,
    required this.times,
    required this.hijriDate,
    required this.locationLabel,
  });

  /// The day these times belong to (time of day is ignored).
  final DateTime date;

  /// Local time of each [Prayer].
  final Map<Prayer, DateTime> times;

  /// e.g. `18 ربيع الثاني 1448 هـ`.
  final String hijriDate;

  /// e.g. `القاهرة، مصر`.
  final String locationLabel;

  DateTime timeOf(Prayer prayer) => times[prayer]!;

  /// The first prayer after [now]. After Isha it is the next day's Fajr,
  /// estimated from today's Fajr time.
  NextPrayer nextPrayer(DateTime now) {
    for (final prayer in Prayer.values) {
      if (!prayer.isPrayer) continue;
      final time = timeOf(prayer);
      if (time.isAfter(now)) return NextPrayer(prayer, time);
    }
    return NextPrayer(
      Prayer.fajr,
      timeOf(Prayer.fajr).add(const Duration(days: 1)),
    );
  }

  @override
  List<Object?> get props => [date, times, hijriDate, locationLabel];
}
