import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/quran/data/datasources/reader_preferences_local_data_source.dart';
import 'package:manara/features/quran/data/repositories/reader_preferences_repository_impl.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime d(int day) => DateTime(2026, 9, day);

void main() {
  group('MushafPage.juzOf', () {
    test('maps pages to their juz', () {
      expect(MushafPage.juzOf(1), 1);
      expect(MushafPage.juzOf(21), 1);
      expect(MushafPage.juzOf(22), 2);
      expect(MushafPage.juzOf(300), 15);
      expect(MushafPage.juzOf(582), 30);
      expect(MushafPage.juzOf(604), 30);
    });
  });

  group('ReaderProgress', () {
    test('currentJuz is 0 before any reading', () {
      expect(const ReaderProgress(lastPage: 300).currentJuz, 0);
      expect(
        const ReaderProgress(lastPage: 300, recentPages: [300]).currentJuz,
        15,
      );
    });

    test('streak counts consecutive days ending today', () {
      final p = ReaderProgress(readingDays: [d(29), d(28), d(27), d(25)]);
      expect(p.streakOn(DateTime(2026, 9, 29, 22)), 3);
    });

    test('streak is still alive when today has no reading yet', () {
      final p = ReaderProgress(readingDays: [d(28), d(27)]);
      expect(p.streakOn(d(29)), 2);
    });

    test('streak resets after a missed day', () {
      final p = ReaderProgress(readingDays: [d(26), d(25)]);
      expect(p.streakOn(d(29)), 0);
      expect(const ReaderProgress().streakOn(d(29)), 0);
    });

    test('streak crosses month boundaries', () {
      final p = ReaderProgress(
        readingDays: [DateTime(2026, 10, 1), d(30), d(29)],
      );
      expect(p.streakOn(DateTime(2026, 10, 1)), 3);
    });
  });

  group('reading days persistence', () {
    Future<ReaderPreferencesRepositoryImpl> repository() async {
      SharedPreferences.setMockInitialValues({});
      return ReaderPreferencesRepositoryImpl(
        ReaderPreferencesLocalDataSourceImpl(
          await SharedPreferences.getInstance(),
        ),
      );
    }

    test('a visit records the day once, newest first', () async {
      final repo = await repository();

      await repo.recordVisit(3, now: DateTime(2026, 9, 28, 8));
      await repo.recordVisit(4, now: DateTime(2026, 9, 29, 9));
      final result = await repo.recordVisit(5, now: DateTime(2026, 9, 29, 21));

      final progress = result.toNullable()!;
      expect(progress.readingDays, [d(29), d(28)]);
      expect(progress.streakOn(d(29)), 2);
    });

    test('reading days survive a reload', () async {
      final repo = await repository();
      await repo.recordVisit(3, now: d(29));

      final reloaded = (await repo.getProgress()).toNullable()!;
      expect(reloaded.readingDays, [d(29)]);
    });

    test('bookmarking keeps the reading days', () async {
      final repo = await repository();
      await repo.recordVisit(3, now: d(29));

      final progress = (await repo.toggleBookmark(3)).toNullable()!;
      expect(progress.readingDays, [d(29)]);
      expect(progress.isBookmarked(3), isTrue);
    });

    test('only the most recent days are kept', () async {
      final repo = await repository();
      late ReaderProgress progress;
      for (var i = 0; i < ReaderProgress.maxReadingDays + 5; i++) {
        progress = (await repo.recordVisit(
          1,
          now: DateTime(2026).add(Duration(days: i)),
        )).toNullable()!;
      }
      expect(progress.readingDays, hasLength(ReaderProgress.maxReadingDays));
    });
  });

  group('daily wird', () {
    Future<ReaderPreferencesRepositoryImpl> repository() async {
      SharedPreferences.setMockInitialValues({});
      return ReaderPreferencesRepositoryImpl(
        ReaderPreferencesLocalDataSourceImpl(
          await SharedPreferences.getInstance(),
        ),
      );
    }

    ReaderProgress right(dynamic either) =>
        (either as dynamic).getOrElse((_) => throw StateError('left'))
            as ReaderProgress;

    test('counts only pages read on the given day', () {
      final progress = ReaderProgress(wirdDate: d(29), wirdPages: const [4, 5]);

      expect(progress.pagesReadOn(DateTime(2026, 9, 29, 23)), 2);
      expect(progress.pagesReadOn(d(30)), 0);
      expect(const ReaderProgress().pagesReadOn(d(29)), 0);
    });

    test('progress is the share of the goal, capped at 1', () {
      final half = ReaderProgress(
        wirdDate: d(29),
        wirdPages: List.generate(ReaderProgress.dailyWirdPages ~/ 2, (i) => i),
      );
      final over = ReaderProgress(
        wirdDate: d(29),
        wirdPages: List.generate(ReaderProgress.dailyWirdPages + 3, (i) => i),
      );

      expect(half.wirdProgressOn(d(29)), 0.5);
      expect(over.wirdProgressOn(d(29)), 1);
    });

    test('a visit adds distinct pages for today', () async {
      final repo = await repository();

      await repo.recordVisit(3, now: DateTime(2026, 9, 29, 8));
      await repo.recordVisit(4, now: DateTime(2026, 9, 29, 9));
      final progress = right(
        await repo.recordVisit(3, now: DateTime(2026, 9, 29, 10)),
      );

      expect(progress.wirdDate, d(29));
      expect(progress.wirdPages, [3, 4]);
    });

    test('starts over on a new day and survives a reload', () async {
      final repo = await repository();

      await repo.recordVisit(3, now: d(28));
      await repo.recordVisit(4, now: d(28));
      await repo.recordVisit(9, now: d(29));
      final progress = right(await repo.getProgress());

      expect(progress.wirdDate, d(29));
      expect(progress.wirdPages, [9]);
      expect(progress.pagesReadOn(d(29)), 1);
    });
  });
}
