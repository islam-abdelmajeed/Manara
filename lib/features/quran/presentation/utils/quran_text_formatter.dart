/// Text helpers for rendering Uthmani Quran text.
abstract final class QuranTextFormatter {
  static const String _ayahStart = '\uFD3F';
  static const String _ayahEnd = '\uFD3E';

  /// Small high waqf (stop) signs: ۖ ۗ ۘ ۙ ۚ ۛ
  static final RegExp _stopMarks = RegExp('[\u06D6-\u06DB]');

  /// Harakat and Quranic annotation marks (tashkeel).
  static final RegExp _tashkeel = RegExp(
    '[\u064B-\u065F\u0670\u06DC\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED]',
  );

  /// Applies the reader's display preferences to an ayah's [text].
  static String format(
    String text, {
    required bool showStopMarks,
    required bool showTashkeel,
  }) {
    var result = text;
    if (!showStopMarks) result = result.replaceAll(_stopMarks, '');
    if (!showTashkeel) result = result.replaceAll(_tashkeel, '');
    return result;
  }

  /// End-of-ayah marker, e.g. `﴿٦﴾`.
  static String ayahEndMarker(int number) {
    return '$_ayahStart${toArabicDigits(number)}$_ayahEnd';
  }

  static String toArabicDigits(int number) {
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return [for (final c in '$number'.codeUnits) digits[c - 0x30]].join();
  }
}
