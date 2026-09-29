import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/error/guard.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/data/datasources/reader_preferences_local_data_source.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/repositories/reader_preferences_repository.dart';

@LazySingleton(as: ReaderPreferencesRepository)
class ReaderPreferencesRepositoryImpl implements ReaderPreferencesRepository {
  const ReaderPreferencesRepositoryImpl(this._local);

  final ReaderPreferencesLocalDataSource _local;

  @override
  ResultFuture<ReaderSettings> getSettings() async {
    return guard(() async => _local.readSettings());
  }

  @override
  ResultFuture<Unit> saveSettings(ReaderSettings settings) {
    return guard(() async {
      await _local.writeSettings(settings);
      return unit;
    });
  }

  @override
  ResultFuture<ReaderProgress> getProgress() {
    return guard(() async => _local.readProgress());
  }

  @override
  ResultFuture<ReaderProgress> recordVisit(int page) {
    return guard(() async {
      final current = _local.readProgress();
      final recent = [
        page,
        ...current.recentPages.where((p) => p != page),
      ].take(ReaderProgress.maxRecent).toList();
      final updated = ReaderProgress(
        lastPage: page,
        recentPages: recent,
        bookmarkedPages: current.bookmarkedPages,
      );
      await _local.writeProgress(updated);
      return updated;
    });
  }

  @override
  ResultFuture<ReaderProgress> toggleBookmark(int page) {
    return guard(() async {
      final current = _local.readProgress();
      final bookmarks = current.isBookmarked(page)
          ? current.bookmarkedPages.where((p) => p != page).toList()
          : [...current.bookmarkedPages, page];
      final updated = ReaderProgress(
        lastPage: current.lastPage,
        recentPages: current.recentPages,
        bookmarkedPages: bookmarks,
      );
      await _local.writeProgress(updated);
      return updated;
    });
  }
}
