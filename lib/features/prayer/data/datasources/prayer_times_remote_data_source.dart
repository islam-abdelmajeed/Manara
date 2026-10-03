import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/core/network/dio_json.dart';
import 'package:manara/features/prayer/data/models/prayer_month_model.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';

abstract interface class PrayerTimesRemoteDataSource {
  /// [month] of [year] plus [PrayerMonth.padding] days on each side.
  Future<PrayerMonth> fetchMonth({
    required PrayerLocation location,
    required PrayerSettings settings,
    required int year,
    required int month,
  });
}

/// Aladhan public API (no key required). Times are requested by
/// coordinates: `timingsByCity` answers unknown cities with another place's
/// times, and `ByAddress` geocodes unreliably.
@LazySingleton(as: PrayerTimesRemoteDataSource)
class PrayerTimesRemoteDataSourceImpl implements PrayerTimesRemoteDataSource {
  const PrayerTimesRemoteDataSourceImpl(this._dio);

  static const String baseUrl = 'https://api.aladhan.com/v1';

  /// Order of Aladhan's `tune` list.
  static const List<String> _tuneOrder = [
    'Imsak',
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Sunset',
    'Isha',
    'Midnight',
  ];

  final Dio _dio;

  @override
  Future<PrayerMonth> fetchMonth({
    required PrayerLocation location,
    required PrayerSettings settings,
    required int year,
    required int month,
  }) async {
    final from = DateTime.utc(year, month, 1 - PrayerMonth.padding);
    final to = DateTime.utc(year, month + 1, PrayerMonth.padding);

    final json = await _dio.getJson(
      '$baseUrl/calendar/from/${_day(from)}/to/${_day(to)}',
      query(location, settings),
    );
    final data = json['data'];
    if (json['code'] != 200 || data is! List<dynamic> || data.isEmpty) {
      throw const ServerException(message: 'تعذّر تحميل مواقيت الصلاة');
    }
    try {
      return PrayerMonthModel.fromAladhan(
        data,
        year: year,
        month: month,
        from: from,
        to: to,
      );
    } on FormatException {
      throw const ServerException(message: 'استجابة غير متوقعة من الخادم');
    } on TypeError {
      throw const ServerException(message: 'استجابة غير متوقعة من الخادم');
    }
  }

  /// Query parameters for [location] and [settings].
  static Map<String, dynamic> query(
    PrayerLocation location,
    PrayerSettings settings,
  ) {
    final tune = {
      'Fajr': settings.tuneOf(Prayer.fajr),
      'Sunrise': settings.tuneOf(Prayer.sunrise),
      'Dhuhr': settings.tuneOf(Prayer.dhuhr),
      'Asr': settings.tuneOf(Prayer.asr),
      'Maghrib': settings.tuneOf(Prayer.maghrib),
      'Isha': settings.tuneOf(Prayer.isha),
    };
    return {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'method': settings.method,
      'school': settings.school.apiValue,
      'latitudeAdjustmentMethod': settings.highLatitudeRule.apiValue,
      if (tune.values.any((m) => m != 0))
        'tune': [for (final key in _tuneOrder) tune[key] ?? 0].join(','),
      'iso8601': 'true',
    };
  }

  /// `DD-MM-YYYY`.
  static String _day(DateTime d) =>
      '${_two(d.day)}-${_two(d.month)}-${d.year.toString().padLeft(4, '0')}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
