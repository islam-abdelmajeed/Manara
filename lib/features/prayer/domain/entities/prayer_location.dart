import 'package:equatable/equatable.dart';

class PrayerLocation extends Equatable {
  const PrayerLocation({
    required this.city,
    required this.country,
    required this.label,
  });

  /// Location shown in the Figma design; used until location picking exists.
  static const cairo = PrayerLocation(
    city: 'Cairo',
    country: 'Egypt',
    label: 'القاهرة، مصر',
  );

  /// City and country as the prayer times API expects them (English).
  final String city;
  final String country;

  /// Arabic label shown to the user.
  final String label;

  @override
  List<Object?> get props => [city, country, label];
}
