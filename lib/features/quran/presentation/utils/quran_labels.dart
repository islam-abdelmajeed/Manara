import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';

/// Arabic labels used by the reader UI.
abstract final class QuranLabels {
  /// Arabic counting: 3–10 take the plural "آيات", everything else "آية".
  static String ayahCount(int count) {
    final plural = count >= 3 && count <= 10;
    return '$count ${plural ? 'آيات' : 'آية'}';
  }

  static String revelation(RevelationPlace place) {
    return place == RevelationPlace.makkah ? 'مكية' : 'مدنية';
  }

  /// Header subtitle, e.g. `مدنية | آية 286`.
  static String headerSubtitle(Surah surah) {
    return '${revelation(surah.revelationPlace)} | آية ${surah.versesCount}';
  }

  /// List subtitle, e.g. `مدنية – 286 آية`.
  static String listSubtitle(Surah surah) {
    return '${revelation(surah.revelationPlace)} – '
        '${ayahCount(surah.versesCount)}';
  }

  /// Index card subtitle, e.g. `مكية | آيات 7` or `مدنية | آية 286`.
  static String cardSubtitle(Surah surah) {
    final count = surah.versesCount;
    final word = count >= 3 && count <= 10 ? 'آيات' : 'آية';
    return '${revelation(surah.revelationPlace)} | $word $count';
  }

  /// `الجزء الأول` … `الجزء الثلاثون`; [juz] is 1-based.
  static String juzName(int juz) => 'الجزء ${_juzOrdinals[juz - 1]}';

  static const List<String> _juzOrdinals = [
    'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', //
    'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
    'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر',
    'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
    'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون',
    'الرابع والعشرون', 'الخامس والعشرون', 'السادس والعشرون',
    'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
  ];

  /// First Mushaf page of each juz (Madani Mushaf, 604 pages).
  static const List<int> juzStartPages = MushafPage.juzStartPages;
}
