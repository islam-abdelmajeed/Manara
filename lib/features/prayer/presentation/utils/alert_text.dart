import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';

/// Title and body of an alert.
(String, String) alertText(AlertEvent event) {
  final prayer = event.prayer.label;
  final inMinutes = 'بعد ${PrayerFormat.minutes(event.minutes)}';
  return switch (event.kind) {
    AlertKind.prayer when event.minutes == 0 => (
      'حان وقت صلاة $prayer',
      'دخل الآن وقت $prayer.',
    ),
    AlertKind.prayer => ('اقترب وقت صلاة $prayer', 'أذان $prayer $inMinutes.'),
    AlertKind.suhoor => ('تنبيه السحور', 'أذان الفجر $inMinutes.'),
    AlertKind.friday => ('تنبيه الجمعة', 'أذان الظهر يوم الجمعة $inMinutes.'),
  };
}
