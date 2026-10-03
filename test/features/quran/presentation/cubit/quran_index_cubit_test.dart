import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/core/utils/arabic_search.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/usecases/get_mushaf_page.dart';
import 'package:manara/features/quran/domain/usecases/get_surahs.dart';
import 'package:manara/features/quran/domain/usecases/reader_progress_usecases.dart';
import 'package:manara/features/quran/presentation/cubit/quran_index_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/quran_fixtures.dart';

class MockGetSurahs extends Mock implements GetSurahs {}

class MockGetReaderProgress extends Mock implements GetReaderProgress {}

class MockGetMushafPage extends Mock implements GetMushafPage {}

final _today = DateTime(2026, 9, 29, 10);

void main() {
  late MockGetSurahs getSurahs;
  late MockGetReaderProgress getProgress;
  late MockGetMushafPage getPage;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    getSurahs = MockGetSurahs();
    getProgress = MockGetReaderProgress();
    getPage = MockGetMushafPage();
    when(() => getSurahs(any())).thenAnswer((_) async => const Right(surahs));
    when(
      () => getProgress(any()),
    ).thenAnswer((_) async => const Right(ReaderProgress()));
    when(
      () => getPage(any()),
    ).thenAnswer((_) async => Right(pageOf(3, firstAyah: 6)));
  });

  QuranIndexCubit build() => QuranIndexCubit(getSurahs, getProgress, getPage);

  group('load', () {
    blocTest<QuranIndexCubit, QuranIndexState>(
      'loads the surahs and skips the last page before any reading',
      build: build,
      act: (c) => c.load(now: _today),
      verify: (c) {
        expect(c.state.status, QuranIndexStatus.success);
        expect(c.state.surahs, surahs);
        expect(c.state.lastRead, isNull);
        verifyNever(() => getPage(any()));
      },
    );

    blocTest<QuranIndexCubit, QuranIndexState>(
      'resolves where reading stopped from the last page',
      setUp: () => when(() => getProgress(any())).thenAnswer(
        (_) async => const Right(ReaderProgress(lastPage: 3, recentPages: [3])),
      ),
      build: build,
      act: (c) => c.load(now: _today),
      verify: (c) {
        expect(
          c.state.lastRead,
          const LastReadPosition(surah: baqarah, ayahNumber: 6),
        );
        verify(() => getPage(3)).called(1);
      },
    );

    blocTest<QuranIndexCubit, QuranIndexState>(
      "counts today's wird pages",
      setUp: () => when(() => getProgress(any())).thenAnswer(
        (_) async => Right(
          ReaderProgress(
            wirdDate: DateTime(2026, 9, 29),
            wirdPages: const [2, 3],
          ),
        ),
      ),
      build: build,
      act: (c) => c.load(now: _today),
      verify: (c) {
        expect(c.state.pagesReadToday, 2);
        expect(c.state.wirdProgress, 2 / ReaderProgress.dailyWirdPages);
      },
    );

    blocTest<QuranIndexCubit, QuranIndexState>(
      'reports a failure but keeps the progress',
      setUp: () {
        when(
          () => getSurahs(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
        when(() => getProgress(any())).thenAnswer(
          (_) async => const Right(ReaderProgress(bookmarkedPages: [7])),
        );
      },
      build: build,
      act: (c) => c.load(now: _today),
      verify: (c) {
        expect(c.state.status, QuranIndexStatus.failure);
        expect(c.state.errorMessage, 'offline');
        expect(c.state.progress.bookmarkedPages, [7]);
      },
    );
  });

  blocTest<QuranIndexCubit, QuranIndexState>(
    'refreshProgress picks up reading done elsewhere, keeping the surahs',
    setUp: () => when(() => getProgress(any())).thenAnswer(
      (_) async => const Right(ReaderProgress(lastPage: 3, recentPages: [3])),
    ),
    build: build,
    seed: () =>
        const QuranIndexState(status: QuranIndexStatus.success, surahs: surahs),
    act: (c) => c.refreshProgress(now: _today),
    verify: (c) {
      expect(c.state.status, QuranIndexStatus.success);
      expect(c.state.progress.recentPages, [3]);
      expect(
        c.state.lastRead,
        const LastReadPosition(surah: baqarah, ayahNumber: 6),
      );
      verifyNever(() => getSurahs(any()));
    },
  );

  group('browsing', () {
    blocTest<QuranIndexCubit, QuranIndexState>(
      'search filters by name without tashkeel and jumps to the surahs tab',
      build: build,
      seed: () => const QuranIndexState(
        status: QuranIndexStatus.success,
        surahs: surahs,
        tab: QuranIndexTab.favorites,
      ),
      act: (c) => c.search('البَقَرَة'),
      verify: (c) {
        expect(c.state.tab, QuranIndexTab.surahs);
        expect(c.state.filteredSurahs, [baqarah]);
      },
    );

    blocTest<QuranIndexCubit, QuranIndexState>(
      'search matches surah numbers and hamza-less spelling',
      build: build,
      seed: () => const QuranIndexState(surahs: surahs),
      act: (c) => c.search('ال عمران'),
      verify: (c) {
        expect(c.state.filteredSurahs, [imran]);
        expect(
          const QuranIndexState(surahs: surahs, query: '٣').filteredSurahs,
          [imran],
        );
      },
    );

    blocTest<QuranIndexCubit, QuranIndexState>(
      'clearing the search keeps the current tab',
      build: build,
      seed: () => const QuranIndexState(tab: QuranIndexTab.juz),
      act: (c) => c.search('  '),
      expect: () => [
        const QuranIndexState(tab: QuranIndexTab.juz, query: '  '),
      ],
    );

    blocTest<QuranIndexCubit, QuranIndexState>(
      'show more adds a page of cards; switching tabs resets it',
      build: build,
      act: (c) => c
        ..showMore()
        ..selectTab(QuranIndexTab.juz),
      expect: () => [
        const QuranIndexState(visibleCount: QuranIndexState.pageSize * 2),
        const QuranIndexState(tab: QuranIndexTab.juz),
      ],
    );
  });

  test('surahAtPage finds the surah a page starts in', () {
    const state = QuranIndexState(surahs: surahs);
    expect(state.surahAtPage(1), fatiha);
    expect(state.surahAtPage(49), baqarah);
    expect(state.surahAtPage(60), imran);
  });

  test('ArabicSearch.normalize unifies letter forms', () {
    expect(ArabicSearch.normalize(' إِبْرَاهِيمَ '), 'ابراهيم');
    expect(
      ArabicSearch.normalize('الفاتحة'),
      ArabicSearch.normalize('الفاتحه'),
    );
    expect(ArabicSearch.normalize('طه'), 'طه');
    expect(ArabicSearch.normalize('١١٤'), '114');
  });
}
