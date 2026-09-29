import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';

enum PrayerTimesStatus { initial, loading, success, failure }

class PrayerTimesState extends Equatable {
  const PrayerTimesState({
    this.status = PrayerTimesStatus.initial,
    this.times,
    this.errorMessage,
  });

  final PrayerTimesStatus status;
  final PrayerTimes? times;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, times, errorMessage];
}

@injectable
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit(this._getPrayerTimes) : super(const PrayerTimesState());

  final GetPrayerTimes _getPrayerTimes;

  Future<void> load({
    DateTime? date,
    PrayerLocation location = PrayerLocation.cairo,
  }) async {
    emit(
      PrayerTimesState(status: PrayerTimesStatus.loading, times: state.times),
    );
    final result = await _getPrayerTimes(
      PrayerTimesParams(date: date ?? DateTime.now(), location: location),
    );
    if (isClosed) return;
    emit(
      result.match(
        (failure) => PrayerTimesState(
          status: PrayerTimesStatus.failure,
          times: state.times,
          errorMessage: failure.message,
        ),
        (times) =>
            PrayerTimesState(status: PrayerTimesStatus.success, times: times),
      ),
    );
  }
}
