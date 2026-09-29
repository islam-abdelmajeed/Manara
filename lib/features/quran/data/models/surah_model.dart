import 'package:manara/features/quran/domain/entities/surah.dart';

/// Parses a chapter from the Quran.com API v4 (`/chapters`).
class SurahModel extends Surah {
  const SurahModel({
    required super.id,
    required super.nameArabic,
    required super.revelationPlace,
    required super.versesCount,
    required super.firstPage,
    required super.lastPage,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] as List<dynamic>).cast<int>();
    return SurahModel(
      id: json['id'] as int,
      nameArabic: json['name_arabic'] as String,
      revelationPlace: json['revelation_place'] == 'makkah'
          ? RevelationPlace.makkah
          : RevelationPlace.madinah,
      versesCount: json['verses_count'] as int,
      firstPage: pages.first,
      lastPage: pages.last,
    );
  }
}
