import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/network/dio_json.dart';
import 'package:manara/features/quran/data/models/ayah_tafsir_model.dart';

abstract interface class TafsirRemoteDataSource {
  /// Tafsir [resourceId] for every ayah of Mushaf [page] (Quran.com).
  Future<List<AyahTafsirModel>> fetchQuranComPage(int resourceId, int page);

  /// Al-Mukhtasar for every ayah of [surah] (QuranEnc).
  Future<List<AyahTafsirModel>> fetchMukhtasarSurah(int surah);
}

@LazySingleton(as: TafsirRemoteDataSource)
class TafsirRemoteDataSourceImpl implements TafsirRemoteDataSource {
  const TafsirRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  /// QuranEnc is published by the Tafsir Center for Quranic Studies, the
  /// author of Al-Mukhtasar, which Quran.com does not carry.
  static const String quranEncUrl = 'https://quranenc.com/api/v1';

  @override
  Future<List<AyahTafsirModel>> fetchQuranComPage(
    int resourceId,
    int page,
  ) async {
    // A Mushaf page has fewer than 50 ayahs, so one request covers it.
    final data = await _dio.getJson('/tafsirs/$resourceId/by_page/$page', {
      'per_page': 50,
    });
    return (data['tafsirs'] as List<dynamic>)
        .map((t) => AyahTafsirModel.fromQuranCom(t as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<AyahTafsirModel>> fetchMukhtasarSurah(int surah) async {
    final data = await _dio.getJson(
      '$quranEncUrl/translation/sura/arabic_mokhtasar/$surah',
    );
    return (data['result'] as List<dynamic>)
        .map((t) => AyahTafsirModel.fromQuranEnc(t as Map<String, dynamic>))
        .toList(growable: false);
  }
}
