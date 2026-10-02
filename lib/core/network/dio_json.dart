import 'package:dio/dio.dart';
import 'package:manara/core/error/exceptions.dart';

extension DioJson on Dio {
  /// GETs a JSON object and maps transport errors to data-layer exceptions:
  /// [NetworkException] when offline or timed out, [ServerException]
  /// otherwise. [path] may be absolute to reach another host.
  Future<Map<String, dynamic>> getJson(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    try {
      final response = await get<Map<String, dynamic>>(
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
