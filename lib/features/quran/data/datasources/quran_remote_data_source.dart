import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/exceptions.dart';
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
    final data = await _get('/chapters', {'language': 'ar'});
    return (data['chapters'] as List<dynamic>)
        .map((c) => SurahModel.fromJson(c as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<MushafPageModel> fetchPage(int pageNumber) async {
    final data = await _get('/verses/by_page/$pageNumber', {
      'fields': 'text_uthmani',
      'per_page': 50,
    });
    return MushafPageModel.fromJson(pageNumber, data);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, dynamic> query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'استجابة فارغة من الخادم');
      }
      return data;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          throw const NetworkException();
        case DioExceptionType.badResponse:
        case DioExceptionType.badCertificate:
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
          throw ServerException(
            message: 'تعذّر تحميل البيانات',
            statusCode: e.response?.statusCode,
          );
      }
    }
  }
}
