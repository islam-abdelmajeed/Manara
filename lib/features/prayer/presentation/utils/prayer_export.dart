import 'dart:convert';

import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';

/// A month of prayer times as an iCalendar file and as a printable page.
abstract final class PrayerExport {
  /// RFC 5545 calendar with one zero-length event per prayer (sunrise is
  /// left out). Times are written in UTC so every calendar app places
  /// them correctly.
  static String ics({
    required PrayerMonth month,
    required PrayerLocation location,
    required DateTime now,
  }) {
    String utc(DateTime t) {
      final u = t.toUtc();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${u.year.toString().padLeft(4, '0')}${two(u.month)}'
          '${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    }

    final stamp = utc(now);
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Manara//Prayer Times//AR',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:${_text('مواقيت الصلاة – ${location.name} – '
      '${PrayerFormat.monthYear(month.year, month.month)}')}',
      for (final day in month.days)
        for (final prayer in Prayer.values.where((p) => p.isPrayer)) ...[
          'BEGIN:VEVENT',
          'UID:${utc(day.date).substring(0, 8)}-${prayer.name}-'
              '${location.id}@manara',
          'DTSTAMP:$stamp',
          'DTSTART:${utc(day.timeOf(prayer).instant)}',
          'DTEND:${utc(day.timeOf(prayer).instant)}',
          'SUMMARY:${_text('${prayer.label} – ${location.name}')}',
          'END:VEVENT',
        ],
      'END:VCALENDAR',
    ];
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  /// Escapes a TEXT value (RFC 5545 §3.3.11).
  static String _text(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');

  /// Folds a content line at 75 octets without splitting a character.
  static String _fold(String line) {
    final out = StringBuffer();
    var octets = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      final size = utf8.encode(char).length;
      if (octets + size > 75) {
        out.write('\r\n ');
        octets = 1;
      }
      out.write(char);
      octets += size;
    }
    return out.toString();
  }

  /// A right-to-left HTML page with the month's table, for printing.
  static String printableHtml({
    required PrayerMonth month,
    required PrayerLocation location,
    required String methodLabel,
  }) {
    const esc = HtmlEscape();
    final title =
        'جدول مواقيت الصلاة الشهري لمدينة ${location.name} – '
        '${PrayerFormat.monthYear(month.year, month.month)}';
    final rows = StringBuffer();
    for (final day in month.days) {
      rows.write(
        '<tr><td>${day.date.day} ${PrayerFormat.weekday(day.date)}</td>',
      );
      rows.write('<td>${day.hijri.shortLabel}</td>');
      for (final prayer in Prayer.values) {
        rows.write(
          '<td>${PrayerFormat.clockWithPeriod(day.timeOf(prayer))}</td>',
        );
      }
      rows.write('</tr>');
    }
    return '<!doctype html><html lang="ar" dir="rtl"><head>'
        '<meta charset="utf-8"><title>${esc.convert(title)}</title>'
        '<style>body{font-family:Tajawal,Arial,sans-serif;margin:24px}'
        'h1{font-size:20px}p{font-size:12px;color:#555}'
        'table{width:100%;border-collapse:collapse;font-size:12px}'
        'th,td{border:1px solid #ccc;padding:4px;text-align:center}'
        'th{background:#eef3f0}</style></head><body>'
        '<h1>${esc.convert(title)}</h1>'
        '<p>${esc.convert(methodLabel)}</p>'
        '<table><thead><tr><th>التاريخ</th><th>التاريخ الهجري</th>'
        '${Prayer.values.map((p) => '<th>${p.label}</th>').join()}'
        '</tr></thead><tbody>$rows</tbody></table>'
        '<p>تُحسب مواقيت الصلاة فلكيًا. قد تختلف إعلانات المسجد المحلي '
        'بدقائق – اتبع مسجدك المحلي كلما أمكن.</p></body></html>';
  }
}
