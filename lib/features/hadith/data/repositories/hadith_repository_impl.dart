import 'package:injectable/injectable.dart';
import 'package:manara/core/error/guard.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/hadith/data/datasources/daily_hadith_local_data_source.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';
import 'package:manara/features/hadith/domain/repositories/hadith_repository.dart';

@LazySingleton(as: HadithRepository)
class HadithRepositoryImpl implements HadithRepository {
  const HadithRepositoryImpl(this._local);

  final DailyHadithLocalDataSource _local;

  @override
  ResultFuture<Hadith> getHadithOfTheDay(DateTime date) {
    return guard(() async {
      final hadiths = _local.all();
      // Days since the epoch in UTC, so the pick changes once per day.
      final day = DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).difference(DateTime.utc(1970)).inDays;
      return hadiths[day % hadiths.length];
    });
  }
}
