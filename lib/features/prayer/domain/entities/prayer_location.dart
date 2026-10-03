import 'package:equatable/equatable.dart';

/// A place prayer times are calculated for. Coordinates and time zones come
/// from GeoNames (CC BY 4.0).
class PrayerLocation extends Equatable {
  const PrayerLocation({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
  });

  /// Default until the user picks a city (GeoNames 360630).
  static const cairo = PrayerLocation(
    id: 360630,
    name: 'القاهرة',
    nameEn: 'Cairo',
    country: 'مصر',
    countryCode: 'EG',
    latitude: 30.06263,
    longitude: 31.24967,
    timeZone: 'Africa/Cairo',
  );

  /// GeoNames id.
  final int id;

  /// Arabic city and country names.
  final String name;
  final String country;

  /// GeoNames' English name, also searchable.
  final String nameEn;

  /// ISO 3166 alpha-2, e.g. `EG`.
  final String countryCode;

  final double latitude;
  final double longitude;

  /// IANA zone, e.g. `Africa/Cairo`.
  final String timeZone;

  /// e.g. `القاهرة، مصر`.
  String get label => '$name، $country';

  @override
  List<Object?> get props => [
    id,
    name,
    nameEn,
    country,
    countryCode,
    latitude,
    longitude,
    timeZone,
  ];
}
