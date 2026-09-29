import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/repositories/reader_preferences_repository.dart';

@injectable
class GetReaderProgress implements UseCase<ReaderProgress, NoParams> {
  const GetReaderProgress(this._repository);

  final ReaderPreferencesRepository _repository;

  @override
  ResultFuture<ReaderProgress> call(NoParams params) {
    return _repository.getProgress();
  }
}

@injectable
class RecordPageVisit implements UseCase<ReaderProgress, int> {
  const RecordPageVisit(this._repository);

  final ReaderPreferencesRepository _repository;

  @override
  ResultFuture<ReaderProgress> call(int page) => _repository.recordVisit(page);
}

@injectable
class ToggleBookmark implements UseCase<ReaderProgress, int> {
  const ToggleBookmark(this._repository);

  final ReaderPreferencesRepository _repository;

  @override
  ResultFuture<ReaderProgress> call(int page) {
    return _repository.toggleBookmark(page);
  }
}
