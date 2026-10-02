import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/network/dio_json.dart';
import 'package:manara/features/quran/data/models/mushaf_page_model.dart';
import 'package:manara/features/quran/data/models/surah_model.dart';

abstract interface class QuranRemoteDataSource {
  Future<List<SurahModel>> fetchSurahs();

  Future<MushafPageModel> fetchPage(int pageNumber);
}

/// Quran.com API v4 (public, no key required).
@LazySingleton(as: QuranRemoteDataSource)
class QuranRemoteDataSourceImpl implements QuranRemoteDataSource {
  const QuranRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<SurahModel>> fetchSurahs() async {
    final data = await _dio.getJson('/chapters', {'language': 'ar'});
    return (data['chapters'] as List<dynamic>)
        .map((c) => SurahModel.fromJson(c as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<MushafPageModel> fetchPage(int pageNumber) async {
    final data = await _dio.getJson('/verses/by_page/$pageNumber', {
      'fields': 'text_uthmani',
      'per_page': 50,
    });
    return MushafPageModel.fromJson(pageNumber, data);
  }
}
