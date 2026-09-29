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

  /// First Mushaf page of each juz (Madani Mushaf, 604 pages).
  static const List<int> juzStartPages = MushafPage.juzStartPages;
}
