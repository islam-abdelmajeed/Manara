import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/repositories/quran_repository.dart';

@injectable
class GetMushafPage implements UseCase<MushafPage, int> {
  const GetMushafPage(this._repository);

  final QuranRepository _repository;

  @override
  ResultFuture<MushafPage> call(int pageNumber) {
    return _repository.getPage(pageNumber);
  }
}
