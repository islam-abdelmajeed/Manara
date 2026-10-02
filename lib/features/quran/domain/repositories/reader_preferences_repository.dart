import 'package:fpdart/fpdart.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';

abstract interface class ReaderPreferencesRepository {
  ResultFuture<ReaderSettings> getSettings();

  ResultFuture<Unit> saveSettings(ReaderSettings settings);

  ResultFuture<ReaderProgress> getProgress();

  /// Stores [page] as the last read page, moves it to the top of the
  /// recent list and marks [now] (defaults to the current time) as a
  /// reading day.
  ResultFuture<ReaderProgress> recordVisit(int page, {DateTime? now});

  /// Adds [page] to the bookmarks, or removes it when already there.
  ResultFuture<ReaderProgress> toggleBookmark(int page);

  /// The tafsir chosen in the reader; [TafsirSource.mukhtasar] by default.
  ResultFuture<TafsirSource> getTafsirSource();

  ResultFuture<Unit> saveTafsirSource(TafsirSource source);
}
