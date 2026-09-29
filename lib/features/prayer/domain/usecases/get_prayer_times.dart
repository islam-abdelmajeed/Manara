import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/repositories/prayer_times_repository.dart';

class PrayerTimesParams extends Equatable {
  const PrayerTimesParams({required this.date, required this.location});

  final DateTime date;
  final PrayerLocation location;

  @override
  List<Object?> get props => [date, location];
}

@injectable
class GetPrayerTimes implements UseCase<PrayerTimes, PrayerTimesParams> {
  const GetPrayerTimes(this._repository);

  final PrayerTimesRepository _repository;

  @override
  ResultFuture<PrayerTimes> call(PrayerTimesParams params) {
    return _repository.getPrayerTimes(
      date: params.date,
      location: params.location,
    );
  }
}
