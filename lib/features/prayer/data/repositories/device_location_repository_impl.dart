import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/repositories/device_location_repository.dart';

@module
abstract class GeolocatorModule {
  @lazySingleton
  GeolocatorPlatform get geolocator => GeolocatorPlatform.instance;
}

/// geolocator, at low accuracy: Android asks for the approximate location
/// only, which is ample for prayer times and the qibla.
@LazySingleton(as: DeviceLocationRepository)
class DeviceLocationRepositoryImpl implements DeviceLocationRepository {
  const DeviceLocationRepositoryImpl(this._geolocator);

  final GeolocatorPlatform _geolocator;

  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.low,
    timeLimit: Duration(seconds: 20),
  );

  @override
  ResultFuture<({double latitude, double longitude})> current() async {
    try {
      if (!await _geolocator.isLocationServiceEnabled()) {
        return const Left(LocationFailure(LocationProblem.serviceOff));
      }
      var permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const Left(LocationFailure(LocationProblem.denied));
        case LocationPermission.deniedForever:
          return const Left(LocationFailure(LocationProblem.deniedForever));
        case LocationPermission.whileInUse ||
            LocationPermission.always ||
            LocationPermission.unableToDetermine:
          break;
      }
      final position = await _geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return Right((
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } on LocationServiceDisabledException {
      return const Left(LocationFailure(LocationProblem.serviceOff));
    } on PermissionDeniedException {
      return const Left(LocationFailure(LocationProblem.denied));
      // Also Errors: an unregistered plugin throws one.
    } catch (_) {
      return const Left(LocationFailure(LocationProblem.unavailable));
    }
  }

  @override
  Future<void> openSettings(LocationProblem problem) async {
    try {
      if (problem == LocationProblem.serviceOff) {
        await _geolocator.openLocationSettings();
      } else {
        await _geolocator.openAppSettings();
      }
    } catch (_) {
      // Nothing to open on this platform (the web); the message says what to
      // do.
    }
  }
}
