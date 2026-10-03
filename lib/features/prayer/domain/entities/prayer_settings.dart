import 'package:equatable/equatable.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

/// Juristic rule for the start of Asr (Aladhan `school`).
enum AsrSchool {
  /// Shadow equal to the object's length (Shafi'i, Maliki, Hanbali).
  standard(0),

  /// Shadow twice the object's length.
  hanafi(1);

  const AsrSchool(this.apiValue);

  final int apiValue;
}

/// How Fajr and Isha are found where twilight never ends in summer
/// (Aladhan `latitudeAdjustmentMethod`).
enum HighLatitudeRule {
  middleOfNight(1),
  oneSeventh(2),
  angleBased(3);

  const HighLatitudeRule(this.apiValue);

  final int apiValue;
}

/// How prayer times and the Hijri date are calculated.
class PrayerSettings extends Equatable {
  const PrayerSettings({
    this.method = egyptianMethod,
    this.school = AsrSchool.standard,
    this.highLatitudeRule = HighLatitudeRule.angleBased,
    this.hijriOffset = 0,
    this.tune = const {},
  });

  /// Aladhan method 5: Egyptian General Authority of Survey.
  static const int egyptianMethod = 5;

  static const int maxHijriOffset = 2;
  static const int maxTune = 30;

  /// Aladhan calculation method id.
  final int method;

  final AsrSchool school;
  final HighLatitudeRule highLatitudeRule;

  /// Days added to the calculated Hijri date, within ±[maxHijriOffset].
  final int hijriOffset;

  /// Minutes added to each time, within ±[maxTune]; missing means 0.
  final Map<Prayer, int> tune;

  int tuneOf(Prayer prayer) => tune[prayer] ?? 0;

  /// Settings that change the calculated times (not the Hijri offset).
  String get calculationKey =>
      '$method|${school.apiValue}|${highLatitudeRule.apiValue}|'
      '${[for (final p in Prayer.values) tuneOf(p)].join(',')}';

  PrayerSettings copyWith({
    int? method,
    AsrSchool? school,
    HighLatitudeRule? highLatitudeRule,
    int? hijriOffset,
    Map<Prayer, int>? tune,
  }) {
    return PrayerSettings(
      method: method ?? this.method,
      school: school ?? this.school,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      tune: tune ?? this.tune,
    );
  }

  @override
  List<Object?> get props => [
    method,
    school,
    highLatitudeRule,
    hijriOffset,
    [for (final p in Prayer.values) tuneOf(p)],
  ];
}
