import 'package:manara/features/prayer/domain/entities/hijri_date.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

/// Text for times, dates and distances in the prayer section. Digits are
/// Latin throughout; 12-hour times take ص / م.
abstract final class PrayerFormat {
  /// Gregorian month names as used in Egypt.
  static const List<String> gregorianMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Indexed by [DateTime.weekday] − 1 (Monday first).
  static const List<String> weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// `05:22` (12-hour, location time).
  static String clock(PrayerTime time) {
    final t = time.local;
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${_two(hour)}:${_two(t.minute)}';
  }

  /// `ص` before noon, `م` from noon.
  static String period(PrayerTime time) => time.local.hour < 12 ? 'ص' : 'م';

  /// `05:22 ص`.
  static String clockWithPeriod(PrayerTime time) =>
      '${clock(time)} ${period(time)}';

  /// Hours, minutes and seconds of [left], each two digits; never negative.
  static (String, String, String) countdown(Duration left) {
    final safe = left.isNegative ? Duration.zero : left;
    return (
      _two(safe.inHours),
      _two(safe.inMinutes % 60),
      _two(safe.inSeconds % 60),
    );
  }

  static String weekday(DateTime date) => weekdays[date.weekday - 1];

  /// `الجمعة، 2 أكتوبر 2026 · 21 ربيع الثاني 1448 هـ`.
  static String fullDate(DateTime date, HijriDate hijri) =>
      '${weekday(date)}، ${date.day} ${gregorianMonths[date.month - 1]} '
      '${date.year} · ${hijri.label}';

  /// `أكتوبر 2026`.
  static String monthYear(int year, int month) =>
      '${gregorianMonths[month - 1]} $year';

  /// `13 ساعة 14 دقيقة`, with Arabic number agreement.
  static String duration(Duration d) {
    final hours = _counted(d.inHours, 'ساعة', 'ساعتان', 'ساعات');
    final minutes = d.inMinutes % 60;
    if (minutes == 0) return hours;
    return '$hours ${_counted(minutes, 'دقيقة', 'دقيقتان', 'دقائق')}';
  }

  /// `10 دقائق`, `15 دقيقة`, `دقيقتان`.
  static String minutes(int n) => _counted(n, 'دقيقة', 'دقيقتان', 'دقائق');

  /// 1: the noun and "واحدة" (both nouns are feminine); 2: the dual;
  /// 3–10: the plural; otherwise the singular after the number.
  static String _counted(int n, String one, String two, String few) =>
      switch (n) {
        1 => '$one واحدة',
        2 => two,
        >= 3 && <= 10 => '$n $few',
        _ => '$n $one',
      };

  /// `1,288 km`.
  static String km(double km) {
    final digits = km.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '$buffer km';
  }

  /// `136.2°`. Ends with a left-to-right mark so the degree sign stays
  /// after the number inside Arabic text.
  static String degrees(double value) => '${value.toStringAsFixed(1)}°‎';

  /// `30.0626, 31.2497`.
  static String coordinates(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}
