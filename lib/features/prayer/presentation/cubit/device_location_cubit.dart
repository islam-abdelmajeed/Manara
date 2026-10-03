import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/repositories/device_location_repository.dart';
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart';

enum DeviceLocationStatus { idle, locating, located, failure }

class DeviceLocationState extends Equatable {
  const DeviceLocationState({
    this.status = DeviceLocationStatus.idle,
    this.location,
    this.failure,
  });

  final DeviceLocationStatus status;

  /// Set when [status] is `located`.
  final PrayerLocation? location;

  /// Set when [status] is `failure`.
  final Failure? failure;

  bool get locating => status == DeviceLocationStatus.locating;

  /// The failure can only be fixed in the system settings.
  bool get needsSettings => switch (failure) {
    final LocationFailure f => f.needsSettings,
    _ => false,
  };

  @override
  List<Object?> get props => [status, location, failure];
}

/// "استخدم موقعي": reads the device's position once, as a location named
/// after the nearest city. Whoever listens applies it.
@injectable
class DeviceLocationCubit extends Cubit<DeviceLocationState> {
  DeviceLocationCubit(this._locate, this._device)
    : super(const DeviceLocationState());

  final LocateDevice _locate;
  final DeviceLocationRepository _device;

  Future<void> locate() async {
    if (state.locating) return;
    emit(const DeviceLocationState(status: DeviceLocationStatus.locating));
    final result = await _locate(const NoParams());
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => DeviceLocationState(
          status: DeviceLocationStatus.failure,
          failure: failure,
        ),
        (location) => DeviceLocationState(
          status: DeviceLocationStatus.located,
          location: location,
        ),
      ),
    );
  }

  /// Opens the settings that fix the last failure.
  Future<void> openSettings() async {
    if (state.failure case LocationFailure(:final problem)) {
      await _device.openSettings(problem);
    }
  }
}
