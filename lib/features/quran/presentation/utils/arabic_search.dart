/// Loose matching for Arabic search input.
abstract final class ArabicSearch {
  // Tashkeel, dagger alef and Quranic annotation marks.
  static final RegExp _marks = RegExp(
    '[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );
  static final RegExp _alef = RegExp('[\u0622\u0623\u0625\u0671]');

  /// Drops marks and tatweel, unifies alef / hamza, taa marbuta and alef
  /// maqsura forms, and converts Arabic-Indic digits.
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.trim().replaceAll(_marks, '').runes) {
      buffer.writeCharCode(switch (rune) {
        >= 0x0660 && <= 0x0669 => rune - 0x0660 + 0x30,
        0x0629 => 0x0647, // ة → ه
        0x0649 => 0x064A, // ى → ي
        _ => rune,
      });
    }
    return buffer.toString().replaceAll(_alef, '\u0627').toLowerCase();
  }
}
