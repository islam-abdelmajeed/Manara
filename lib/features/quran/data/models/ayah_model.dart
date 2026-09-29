import 'package:manara/features/quran/domain/entities/ayah.dart';

/// Parses a verse from the Quran.com API v4 (`/verses/by_page`).
class AyahModel extends Ayah {
  const AyahModel({
    required super.surahNumber,
    required super.number,
    required super.text,
    required super.pageNumber,
    required super.juzNumber,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    final key = (json['verse_key'] as String).split(':');
    return AyahModel(
      surahNumber: int.parse(key[0]),
      number: int.parse(key[1]),
      text: json['text_uthmani'] as String,
      pageNumber: json['page_number'] as int,
      juzNumber: json['juz_number'] as int,
    );
  }
}
