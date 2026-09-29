/// Raster images exported from Figma.
abstract final class AppImages {
  static const String _base = 'assets/images';
  static const String _home = '$_base/home';

  /// Lantern logo (Figma component "لوجو"), exported at 4x.
  static const String logo = '$_base/logo.png';

  // Home (Figma "Desktop - 1").
  static const String homeHero = '$_home/hero.webp';
  static const String quickQuran = '$_home/quick_quran.webp';
  static const String quickQibla = '$_home/quick_qibla.webp';
  static const String quickPrayer = '$_home/quick_prayer.webp';
  static const String quickAdhkar = '$_home/quick_adhkar.webp';
  static const String quickTasbih = '$_home/quick_tasbih.webp';
  static const String cardHadith = '$_home/card_hadith.webp';
  static const String cardPrayer = '$_home/card_prayer.webp';
  static const String cardAdhkar = '$_home/card_adhkar.webp';
  static const String cardJourney = '$_home/card_journey.webp';

  /// "كنوز منارة" banners; their titles are part of the artwork.
  static const String treasureFootsteps = '$_home/treasure_footsteps.webp';
  static const String treasureKids = '$_home/treasure_kids.webp';
  static const String treasureRecitation = '$_home/treasure_recitation.webp';
  static const String treasureVoiceRooms = '$_home/treasure_voice_rooms.webp';
}
