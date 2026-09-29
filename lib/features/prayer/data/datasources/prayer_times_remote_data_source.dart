import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/features/prayer/data/models/prayer_times_model.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';

abstract interface class PrayerTimesRemoteDataSource {
  Future<PrayerTimesModel> fetch({
    required DateTime date,
    required PrayerLocation location,
  });
}

/// Aladhan public API (no key required).
@LazySingleton(as: PrayerTimesRemoteDataSource)
class PrayerTimesRemoteDataSourceImpl implements PrayerTimesRemoteDataSource {
  const PrayerTimesRemoteDataSourceImpl(this._dio);

  static const String baseUrl = 'https://api.aladhan.com/v1';

  /// Egyptian General Authority of Survey.
  static const int _method = 5;

  final Dio _dio;

  @override
  Future<PrayerTimesModel> fetch({
    required DateTime date,
    required PrayerLocation location,
  }) async {
    final day =
        '${_two(date.day)}-${_two(date.month)}-${date.year.toString().padLeft(4, '0')}';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/timingsByCity/$day',
        queryParameters: {
          'city': location.city,
          'country': location.country,
          'method': _method,
        },
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ServerException(message: 'استجابة غير متوقعة من الخادم');
      }
      return PrayerTimesModel.fromJson(data, date: date, location: location);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        throw ServerException(
          message: 'تعذّر تحميل مواقيت الصلاة',
          statusCode: e.response?.statusCode,
        );
      }
      throw const NetworkException();
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
