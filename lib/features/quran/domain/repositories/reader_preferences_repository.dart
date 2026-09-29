import 'package:fpdart/fpdart.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';

abstract interface class ReaderPreferencesRepository {
  ResultFuture<ReaderSettings> getSettings();

  ResultFuture<Unit> saveSettings(ReaderSettings settings);

  ResultFuture<ReaderProgress> getProgress();

  /// Stores [page] as the last read page and moves it to the top of the
  /// recent list.
  ResultFuture<ReaderProgress> recordVisit(int page);

  /// Adds [page] to the bookmarks, or removes it when already there.
  ResultFuture<ReaderProgress> toggleBookmark(int page);
}
