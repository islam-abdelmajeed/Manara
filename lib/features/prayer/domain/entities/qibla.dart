import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Direction and distance to the Kaaba along the great circle.
class Qibla extends Equatable {
  const Qibla({required this.bearing, required this.distanceKm});

  /// From [latitude], [longitude] (degrees).
  factory Qibla.from(double latitude, double longitude) {
    return Qibla(
      bearing: bearingBetween(
        latitude,
        longitude,
        kaabaLatitude,
        kaabaLongitude,
      ),
      distanceKm: distanceKmBetween(
        latitude,
        longitude,
        kaabaLatitude,
        kaabaLongitude,
      ),
    );
  }

  /// The Kaaba's position as used by the Aladhan Qibla API; bearings from
  /// this formula match `/v1/qibla` within 0.0001°.
  static const double kaabaLatitude = 21.4225241;
  static const double kaabaLongitude = 39.8261818;

  /// IUGG mean Earth radius.
  static const double earthRadiusKm = 6371.0088;

  /// Degrees clockwise from true north, in [0, 360).
  final double bearing;

  final double distanceKm;

  /// Initial great-circle bearing from point 1 to point 2, in degrees
  /// clockwise from true north.
  static double bearingBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final p1 = _rad(lat1);
    final p2 = _rad(lat2);
    final dl = _rad(lng2 - lng1);
    final y = math.sin(dl) * math.cos(p2);
    final x =
        math.cos(p1) * math.sin(p2) -
        math.sin(p1) * math.cos(p2) * math.cos(dl);
    final degrees = math.atan2(y, x) * 180 / math.pi;
    return (degrees + 360) % 360;
  }

  /// Haversine distance in kilometres.
  static double distanceKmBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dp = _rad(lat2 - lat1);
    final dl = _rad(lng2 - lng1);
    final a =
        math.pow(math.sin(dp / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dl / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Eight-point compass abbreviation of [bearing], e.g. `ج ق` for 136°.
  String get directionLabel {
    const labels = ['ش', 'ش ق', 'ق', 'ج ق', 'ج', 'ج غ', 'غ', 'ش غ'];
    return labels[((bearing + 22.5) % 360 ~/ 45)];
  }

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  List<Object?> get props => [bearing, distanceKm];
}
