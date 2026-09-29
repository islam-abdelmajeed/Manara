import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/repositories/reader_preferences_repository.dart';

@injectable
class GetReaderSettings implements UseCase<ReaderSettings, NoParams> {
  const GetReaderSettings(this._repository);

  final ReaderPreferencesRepository _repository;

  @override
  ResultFuture<ReaderSettings> call(NoParams params) {
    return _repository.getSettings();
  }
}

@injectable
class SaveReaderSettings implements UseCase<Unit, ReaderSettings> {
  const SaveReaderSettings(this._repository);

  final ReaderPreferencesRepository _repository;

  @override
  ResultFuture<Unit> call(ReaderSettings params) {
    return _repository.saveSettings(params);
  }
}
