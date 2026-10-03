import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';

abstract interface class CityCatalogDataSource {
  /// The bundled cities (assets/data/cities.json, built from GeoNames by
  /// tool/build_cities.py).
  Future<List<PrayerLocation>> loadCities();
}

@LazySingleton(as: CityCatalogDataSource)
class CityCatalogDataSourceImpl implements CityCatalogDataSource {
  const CityCatalogDataSourceImpl(this._bundle);

  static const String asset = 'assets/data/cities.json';

  final AssetBundle _bundle;

  @override
  Future<List<PrayerLocation>> loadCities() async {
    try {
      // The repository keeps the parsed list; the bundle needn't cache it.
      final raw =
          jsonDecode(await _bundle.loadString(asset, cache: false))
              as List<dynamic>;
      return [
        for (final item in raw.cast<Map<String, dynamic>>())
          PrayerLocation(
            id: item['id'] as int,
            name: item['name'] as String,
            nameEn: item['nameEn'] as String,
            country: item['country'] as String,
            countryCode: item['countryCode'] as String,
            latitude: (item['lat'] as num).toDouble(),
            longitude: (item['lng'] as num).toDouble(),
            timeZone: item['timeZone'] as String,
          ),
      ];
    } on FormatException {
      throw const CacheException('تعذّر قراءة قائمة المدن');
    } on TypeError {
      throw const CacheException('تعذّر قراءة قائمة المدن');
    }
  }
}
