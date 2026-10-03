import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';

/// The device's position (GPS, network or the browser), asked for only when
/// the user taps "استخدم موقعي". Failures are [LocationFailure]s.
abstract interface class DeviceLocationRepository {
  ResultFuture<({double latitude, double longitude})> current();

  /// Opens the system page that fixes [problem] (location services, or the
  /// app's permissions).
  Future<void> openSettings(LocationProblem problem);
}
