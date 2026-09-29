abstract final class AppRoutes {
  static const String home = '/';

  /// Quran index: surahs, juz, recent pages and favorites.
  static const String quran = '/quran';

  /// Mushaf reader; opens the last read page unless given one.
  static const String quranReader = '/quran/read';

  static String quranReaderAt(int page) => '$quranReader?page=$page';
}
