import 'package:equatable/equatable.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

/// Alert for one prayer.
class PrayerAlert extends Equatable {
  const PrayerAlert({this.enabled = false, this.minutesBefore = 0});

  /// Choices for [minutesBefore]; 0 alerts at the time itself.
  static const List<int> beforeChoices = [0, 5, 10, 15, 20, 30];

  final bool enabled;
  final int minutesBefore;

  PrayerAlert copyWith({bool? enabled, int? minutesBefore}) => PrayerAlert(
    enabled: enabled ?? this.enabled,
    minutesBefore: minutesBefore ?? this.minutesBefore,
  );

  @override
  List<Object?> get props => [enabled, minutesBefore];
}

/// What the user asked to be alerted to. Everything is off until chosen.
class AlertSettings extends Equatable {
  const AlertSettings({
    this.prayers = const {},
    this.suhoor = false,
    this.friday = false,
  });

  /// Figma: "قبل أذان الفجر بـ ٤٠ دقيقة".
  static const int suhoorMinutes = 40;

  /// Figma: "يوم الجمعة قبل صلاة الجمعة بـ ٦٠ دقيقة" (Dhuhr on Friday).
  static const int fridayMinutes = 60;

  /// The five prayers (sunrise is not one); missing means off.
  final Map<Prayer, PrayerAlert> prayers;

  final bool suhoor;
  final bool friday;

  PrayerAlert alertOf(Prayer prayer) => prayers[prayer] ?? const PrayerAlert();

  bool get anyEnabled =>
      suhoor || friday || prayers.values.any((a) => a.enabled);

  AlertSettings copyWith({
    Map<Prayer, PrayerAlert>? prayers,
    bool? suhoor,
    bool? friday,
  }) => AlertSettings(
    prayers: prayers ?? this.prayers,
    suhoor: suhoor ?? this.suhoor,
    friday: friday ?? this.friday,
  );

  AlertSettings withPrayer(Prayer prayer, PrayerAlert alert) =>
      copyWith(prayers: {...prayers, prayer: alert});

  @override
  List<Object?> get props => [
    [
      for (final p in Prayer.values)
        if (p.isPrayer) alertOf(p),
    ],
    suhoor,
    friday,
  ];
}

enum AlertKind { prayer, suhoor, friday }

/// A moment to alert at: [minutes] before [prayer]'s time (0 = at it).
class AlertEvent extends Equatable {
  const AlertEvent({
    required this.at,
    required this.kind,
    required this.prayer,
    required this.minutes,
  });

  final DateTime at;
  final AlertKind kind;

  /// The prayer the alert leads to (Fajr for suhoor, Dhuhr on Friday).
  final Prayer prayer;
  final int minutes;

  /// The first alert strictly after [after] for [times] (today and
  /// tomorrow), or `null` when none is set.
  static AlertEvent? next(
    PrayerTimes times,
    AlertSettings settings,
    DateTime after,
  ) {
    final events = upcoming(
      [times.today, times.tomorrow],
      settings,
      after,
      limit: 1,
    );
    return events.isEmpty ? null : events.first;
  }

  /// The alerts strictly after [after] on [days], soonest first; at most
  /// [limit] of them when given.
  static List<AlertEvent> upcoming(
    Iterable<PrayerDay> days,
    AlertSettings settings,
    DateTime after, {
    int? limit,
  }) {
    final events = <AlertEvent>[];
    void add(PrayerDay day, AlertKind kind, Prayer prayer, int minutes) =>
        events.add(
          AlertEvent(
            at: day.timeOf(prayer).instant.subtract(Duration(minutes: minutes)),
            kind: kind,
            prayer: prayer,
            minutes: minutes,
          ),
        );

    for (final day in days) {
      for (final prayer in Prayer.values.where((p) => p.isPrayer)) {
        final alert = settings.alertOf(prayer);
        if (alert.enabled) {
          add(day, AlertKind.prayer, prayer, alert.minutesBefore);
        }
      }
      if (settings.suhoor) {
        add(day, AlertKind.suhoor, Prayer.fajr, AlertSettings.suhoorMinutes);
      }
      if (settings.friday && day.date.weekday == DateTime.friday) {
        add(day, AlertKind.friday, Prayer.dhuhr, AlertSettings.fridayMinutes);
      }
    }
    events
      ..removeWhere((e) => !e.at.isAfter(after))
      ..sort((a, b) => a.at.compareTo(b.at));
    return limit == null || events.length <= limit
        ? events
        : events.sublist(0, limit);
  }

  @override
  List<Object?> get props => [at, kind, prayer, minutes];
}
