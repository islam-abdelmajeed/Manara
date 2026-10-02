import 'package:manara/features/quran/domain/entities/tafsir.dart';

class AyahTafsirModel extends AyahTafsir {
  const AyahTafsirModel({required super.ayahKey, required super.paragraphs});

  /// An item of Quran.com `/tafsirs/{id}/by_page/{page}`; `text` is HTML.
  factory AyahTafsirModel.fromQuranCom(Map<String, dynamic> json) {
    return AyahTafsirModel(
      ayahKey: json['verse_key'] as String,
      paragraphs: htmlParagraphs(json['text'] as String? ?? ''),
    );
  }

  /// An item of QuranEnc `/translation/sura/arabic_mokhtasar/{sura}`;
  /// `translation` is plain text.
  factory AyahTafsirModel.fromQuranEnc(Map<String, dynamic> json) {
    final surah = int.parse('${json['sura']}');
    final ayah = int.parse('${json['aya']}');
    final text = _stripGroupPrefix(
      (json['translation'] as String? ?? '').trim(),
      ayah,
    );
    return AyahTafsirModel(
      ayahKey: '$surah:$ayah',
      paragraphs: text.isEmpty ? const [] : [text],
    );
  }

  /// Ayahs explained together carry their range first, e.g. `3 - 4 - …`.
  /// The reader already shows the ayah numbers, so the range is removed,
  /// but only when [ayah] lies inside it; the text is otherwise untouched.
  static final RegExp _groupPrefix = RegExp(r'^(\d+)\s*-\s*(\d+)\s*-\s*');

  static String _stripGroupPrefix(String text, int ayah) {
    final match = _groupPrefix.firstMatch(text);
    if (match == null) return text;
    final from = int.parse(match.group(1)!);
    final to = int.parse(match.group(2)!);
    if (ayah < from || ayah > to) return text;
    return text.substring(match.end);
  }

  static final RegExp _paragraphBreak = RegExp(
    r'<\s*(?:/p|p(?:\s[^>]*)?|br\s*/?)\s*>',
    caseSensitive: false,
  );
  static final RegExp _tag = RegExp('<[^>]*>');
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _numericEntity = RegExp(r'&#(x?)([0-9a-fA-F]+);');
  static const Map<String, String> _namedEntities = {
    '&nbsp;': ' ',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&amp;': '&',
  };

  /// Splits tafsir HTML into plain-text paragraphs. Only `<p>` and `<br>`
  /// carry structure; inline tags (styling spans) are dropped and their
  /// text kept.
  static List<String> htmlParagraphs(String html) {
    return [
      for (final chunk in html.split(_paragraphBreak))
        if (_clean(chunk) case final text when text.isNotEmpty) text,
    ];
  }

  static String _clean(String chunk) {
    var text = chunk.replaceAll(_tag, '');
    text = text.replaceAllMapped(_numericEntity, (m) {
      final code = int.parse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16);
      return String.fromCharCode(code);
    });
    // `&amp;` last so an escaped entity is not decoded twice.
    _namedEntities.forEach((entity, value) {
      text = text.replaceAll(entity, value);
    });
    return text.replaceAll(_whitespace, ' ').trim();
  }
}
