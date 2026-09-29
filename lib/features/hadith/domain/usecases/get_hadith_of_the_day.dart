import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';
import 'package:manara/features/hadith/domain/repositories/hadith_repository.dart';

@injectable
class GetHadithOfTheDay implements UseCase<Hadith, DateTime> {
  const GetHadithOfTheDay(this._repository);

  final HadithRepository _repository;

  @override
  ResultFuture<Hadith> call(DateTime date) {
    return _repository.getHadithOfTheDay(date);
  }
}
