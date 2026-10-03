import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/repositories/prayer_times_repository.dart';

class PrayerMonthParams extends Equatable {
  const PrayerMonthParams({
    required this.location,
    required this.settings,
    required this.year,
    required this.month,
  });

  final PrayerLocation location;
  final PrayerSettings settings;
  final int year;
  final int month;

  @override
  List<Object?> get props => [location, settings, year, month];
}

/// A month of times with the user's Hijri offset applied.
@injectable
class GetPrayerMonth implements UseCase<PrayerMonth, PrayerMonthParams> {
  const GetPrayerMonth(this._repository);

  final PrayerTimesRepository _repository;

  @override
  ResultFuture<PrayerMonth> call(PrayerMonthParams params) async {
    final result = await _repository.getMonth(
      location: params.location,
      settings: params.settings,
      year: params.year,
      month: params.month,
    );
    return result.map((m) => m.withHijriOffset(params.settings.hijriOffset));
  }
}

class UpcomingDaysParams extends Equatable {
  const UpcomingDaysParams({
    required this.now,
    required this.location,
    required this.settings,
    required this.count,
  });

  final DateTime now;
  final PrayerLocation location;
  final PrayerSettings settings;

  /// How many days, from today at the location.
  final int count;

  @override
  List<Object?> get props => [now, location, settings, count];
}

/// Today at the location and the days after it, up to
/// [UpcomingDaysParams.count]. The next month is fetched when this month's
/// padding runs out; without it, fewer days come back.
@injectable
class GetUpcomingPrayerDays
    implements UseCase<List<PrayerDay>, UpcomingDaysParams> {
  const GetUpcomingPrayerDays(this._getMonth);

  final GetPrayerMonth _getMonth;

  @override
  ResultFuture<List<PrayerDay>> call(UpcomingDaysParams params) async {
    final utc = params.now.toUtc();
    Future<Either<Failure, PrayerMonth>> month(int year, int month) =>
        _getMonth(
          PrayerMonthParams(
            location: params.location,
            settings: params.settings,
            year: year,
            month: month,
          ),
        );

    final first = await month(utc.year, utc.month);
    return first.fold(Left.new, (current) async {
      final today = current.dayAt(params.now);
      if (today == null) {
        return const Left(ServerFailure('تعذّر تحديد مواقيت اليوم'));
      }
      final days = current.allDays
          .skip(current.allDays.indexOf(today))
          .take(params.count)
          .toList();
      if (days.length < params.count) {
        final next = DateTime.utc(utc.year, utc.month + 1);
        final more = await month(next.year, next.month);
        for (final day in more.getOrElse((_) => current).allDays) {
          if (days.length == params.count) break;
          if (day.start.isAfter(days.last.start)) days.add(day);
        }
      }
      return Right(days);
    });
  }
}

class PrayerTimesParams extends Equatable {
  const PrayerTimesParams({
    required this.now,
    required this.location,
    required this.settings,
  });

  final DateTime now;
  final PrayerLocation location;
  final PrayerSettings settings;

  @override
  List<Object?> get props => [now, location, settings];
}

/// The times of the day containing [PrayerTimesParams.now] at the location,
/// with tomorrow's.
@injectable
class GetPrayerTimes implements UseCase<PrayerTimes, PrayerTimesParams> {
  const GetPrayerTimes(this._getMonth);

  final GetPrayerMonth _getMonth;

  @override
  ResultFuture<PrayerTimes> call(PrayerTimesParams params) async {
    // The UTC month: every location's date is within a day of the UTC date
    // (offsets run from −12 to +14 hours), which the padding covers.
    final now = params.now;
    final utc = now.toUtc();
    final result = await _getMonth(
      PrayerMonthParams(
        location: params.location,
        settings: params.settings,
        year: utc.year,
        month: utc.month,
      ),
    );
    return result.flatMap((month) {
      final today = month.dayAt(now);
      final tomorrow = today == null ? null : month.dayAfter(today);
      if (today == null || tomorrow == null) {
        return const Left(ServerFailure('تعذّر تحديد مواقيت اليوم'));
      }
      return Right(
        PrayerTimes(
          location: params.location,
          today: today,
          tomorrow: tomorrow,
          fetchedAt: month.fetchedAt,
        ),
      );
    });
  }
}
