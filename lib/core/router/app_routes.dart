abstract final class AppRoutes {
  static const String home = '/';

  /// Quran index: surahs, juz, recent pages and favorites.
  static const String quran = '/quran';

  /// Mushaf reader; opens the last read page unless given one.
  static const String quranReader = '/quran/read';

  static String quranReaderAt(int page) => '$quranReader?page=$page';

  /// Prayer section: today's times and the qibla.
  static const String prayer = '/prayer';

  /// The qibla part of [prayer].
  static const String qibla = '$prayer?section=qibla';

  static const String prayerMonthly = '$prayer/monthly';
  static const String prayerAlerts = '$prayer/alerts';
  static const String prayerSettings = '$prayer/settings';

  /// Settings, opened on the city list ([countryCode] limits it, e.g. `EG`).
  static String prayerCities({String? countryCode}) =>
      '$prayerSettings?cities=${countryCode ?? 'all'}';
}
