import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/domain/repositories/quran_repository.dart';

@injectable
class GetSurahs implements UseCase<List<Surah>, NoParams> {
  const GetSurahs(this._repository);

  final QuranRepository _repository;

  @override
  ResultFuture<List<Surah>> call(NoParams params) => _repository.getSurahs();
}
