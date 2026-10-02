import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/quran/data/datasources/reader_preferences_local_data_source.dart';
import 'package:manara/features/quran/data/repositories/reader_preferences_repository_impl.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ReaderPreferencesRepositoryImpl> _repository([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ReaderPreferencesRepositoryImpl(
    ReaderPreferencesLocalDataSourceImpl(prefs),
  );
}

T _right<T>(dynamic either) =>
    (either as dynamic).getOrElse((_) => throw StateError('left')) as T;

void main() {
  group('settings', () {
    test('returns Figma defaults on first launch', () async {
      final repository = await _repository();

      final settings = _right<ReaderSettings>(await repository.getSettings());
      expect(settings, const ReaderSettings());
      expect(settings.lineSpacing, LineSpacing.large);
    });

    test('persists every field', () async {
      final repository = await _repository();
      const saved = ReaderSettings(
        fontScale: 1.3,
        lineSpacing: LineSpacing.medium,
        textColorIndex: 2,
        backgroundColorIndex: 3,
        showStopMarks: false,
        showTashkeel: false,
        highlightWhilePlaying: false,
      );

      await repository.saveSettings(saved);

      expect(_right<ReaderSettings>(await repository.getSettings()), saved);
    });

    test('clamps an out-of-range stored font scale', () async {
      final repository = await _repository({'reader.fontScale': 9.0});

      final settings = _right<ReaderSettings>(await repository.getSettings());
      expect(settings.fontScale, ReaderSettings.maxFontScale);
    });

    test('ignores an unknown stored enum index', () async {
      final repository = await _repository({'reader.lineSpacing': 42});

      final settings = _right<ReaderSettings>(await repository.getSettings());
      expect(settings.lineSpacing, LineSpacing.large);
    });
  });

  group('progress', () {
    test('starts on page 1 with nothing saved', () async {
      final repository = await _repository();

      final progress = _right<ReaderProgress>(await repository.getProgress());
      expect(progress.lastPage, 1);
      expect(progress.recentPages, isEmpty);
      expect(progress.bookmarkedPages, isEmpty);
    });

    test('recordVisit stores the last page and keeps recents unique', () async {
      final repository = await _repository();

      await repository.recordVisit(5);
      await repository.recordVisit(7);
      final progress = _right<ReaderProgress>(await repository.recordVisit(5));

      expect(progress.lastPage, 5);
      expect(progress.recentPages, [5, 7]);
    });

    test('recent pages are capped', () async {
      final repository = await _repository();

      late ReaderProgress progress;
      for (var page = 1; page <= ReaderProgress.maxRecent + 5; page++) {
        progress = _right<ReaderProgress>(await repository.recordVisit(page));
      }

      expect(progress.recentPages, hasLength(ReaderProgress.maxRecent));
      expect(progress.recentPages.first, ReaderProgress.maxRecent + 5);
    });

    test('toggleBookmark adds then removes a page', () async {
      final repository = await _repository();

      final added = _right<ReaderProgress>(await repository.toggleBookmark(9));
      expect(added.isBookmarked(9), isTrue);

      final removed = _right<ReaderProgress>(
        await repository.toggleBookmark(9),
      );
      expect(removed.isBookmarked(9), isFalse);
    });

    test('bookmarks survive a new visit', () async {
      final repository = await _repository();

      await repository.toggleBookmark(9);
      final progress = _right<ReaderProgress>(await repository.recordVisit(3));

      expect(progress.bookmarkedPages, [9]);
    });
  });

  group('tafsir source', () {
    test('defaults to Al-Mukhtasar', () async {
      final repository = await _repository();

      expect(
        _right<TafsirSource>(await repository.getTafsirSource()),
        TafsirSource.mukhtasar,
      );
    });

    test('persists the choice by name', () async {
      final repository = await _repository();

      await repository.saveTafsirSource(TafsirSource.ibnKathir);

      expect(
        _right<TafsirSource>(await repository.getTafsirSource()),
        TafsirSource.ibnKathir,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('reader.tafsir'), 'ibnKathir');
    });

    test('falls back to the default for an unknown stored name', () async {
      final repository = await _repository({'reader.tafsir': 'tabari'});

      expect(
        _right<TafsirSource>(await repository.getTafsirSource()),
        TafsirSource.mukhtasar,
      );
    });
  });
}
