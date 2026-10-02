import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';
import 'package:manara/features/quran/domain/repositories/reader_preferences_repository.dart';
import 'package:manara/features/quran/domain/repositories/tafsir_repository.dart';

class PageTafsirParams extends Equatable {
  const PageTafsirParams({required this.source, required this.page});

  final TafsirSource source;
  final MushafPage page;

  @override
  List<Object?> get props => [source, page];
}

@injectable
class GetPageTafsir implements UseCase<List<AyahTafsir>, PageTafsirParams> {
  const GetPageTafsir(this._repository);

  final TafsirRepository _repository;

  @override
  ResultFuture<List<AyahTafsir>> call(PageTafsirParams params) {
    return _repository.getPageTafsir(params.source, params.page);
  }
}

@injectable
class GetTafsirSource implements UseCase<TafsirSource, NoParams> {
  const GetTafsirSource(this._repository);

  final ReaderPreferencesRepository _repository;

  @override
  ResultFuture<TafsirSource> call(NoParams params) {
    return _repository.getTafsirSource();
  }
}

@injectable
class SaveTafsirSource implements UseCase<Unit, TafsirSource> {
  const SaveTafsirSource(this._repository);

  final ReaderPreferencesRepository _repository;

  @override
  ResultFuture<Unit> call(TafsirSource params) {
    return _repository.saveTafsirSource(params);
  }
}
