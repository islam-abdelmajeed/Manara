import 'package:manara/features/quran/data/models/ayah_model.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';

class MushafPageModel extends MushafPage {
  const MushafPageModel({required super.number, required super.ayahs});

  factory MushafPageModel.fromJson(int number, Map<String, dynamic> json) {
    final verses = (json['verses'] as List<dynamic>)
        .map((v) => AyahModel.fromJson(v as Map<String, dynamic>))
        .toList(growable: false);
    return MushafPageModel(number: number, ayahs: verses);
  }
}
