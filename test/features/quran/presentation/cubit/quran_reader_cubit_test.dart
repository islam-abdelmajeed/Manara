import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/usecases/get_mushaf_page.dart';
import 'package:manara/features/quran/domain/usecases/get_surahs.dart';
import 'package:manara/features/quran/domain/usecases/reader_progress_usecases.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/quran_fixtures.dart';

class MockGetSurahs extends Mock implements GetSurahs {}

class MockGetMushafPage extends Mock implements GetMushafPage {}

class MockGetReaderProgress extends Mock implements GetReaderProgress {}

class MockRecordPageVisit extends Mock implements RecordPageVisit {}

class MockToggleBookmark extends Mock implements ToggleBookmark {}

void main() {
  late MockGetSurahs getSurahs;
  late MockGetMushafPage getPage;
  late MockGetReaderProgress getProgress;
  late MockRecordPageVisit recordVisit;
  late MockToggleBookmark toggleBookmark;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    getSurahs = MockGetSurahs();
    getPage = MockGetMushafPage();
    getProgress = MockGetReaderProgress();
    recordVisit = MockRecordPageVisit();
    toggleBookmark = MockToggleBookmark();

    when(() => getSurahs(any())).thenAnswer((_) async => const Right(surahs));
    when(
      () => getProgress(any()),
    ).thenAnswer((_) async => const Right(ReaderProgress(lastPage: 4)));
    when(() => getPage(any())).thenAnswer((i) async {
      return Right(pageOf(i.positionalArguments.first as int));
    });
    when(() => recordVisit(any())).thenAnswer((i) async {
      final page = i.positionalArguments.first as int;
      return Right(ReaderProgress(lastPage: page, recentPages: [page]));
    });
  });

  QuranReaderCubit build() => QuranReaderCubit(
    getSurahs,
    getPage,
    getProgress,
    recordVisit,
    toggleBookmark,
  );

  group('init', () {
    test('opens the last read page and loads the surah list', () async {
      final cubit = build();
      await cubit.init();

      expect(cubit.state.status, ReaderStatus.success);
      expect(cubit.state.pageNumber, 4);
      expect(cubit.state.page?.number, 4);
      expect(cubit.state.surahs, surahs);
      expect(cubit.state.progress.lastPage, 4);
      await cubit.close();
    });

    test('an explicit initial page wins over the saved one', () async {
      final cubit = build();
      await cubit.init(initialPage: 50);

      expect(cubit.state.pageNumber, 50);
      await cubit.close();
    });

    test('still opens a page when the surah list fails', () async {
      when(
        () => getSurahs(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      final cubit = build();
      await cubit.init();

      expect(cubit.state.status, ReaderStatus.success);
      expect(cubit.state.surahs, isEmpty);
      expect(cubit.state.currentSurah, isNull);
      await cubit.close();
    });
  });

  group('goToPage', () {
    test('clamps to the Mushaf range', () async {
      final cubit = build();

      await cubit.goToPage(0);
      expect(cubit.state.pageNumber, MushafPage.firstNumber);
      await cubit.goToPage(9999);
      expect(cubit.state.pageNumber, MushafPage.lastNumber);
      await cubit.close();
    });

    blocTest<QuranReaderCubit, QuranReaderState>(
      'emits loading then success and records the visit',
      build: build,
      act: (cubit) => cubit.goToPage(3),
      verify: (cubit) {
        expect(cubit.state.status, ReaderStatus.success);
        expect(cubit.state.progress.recentPages, [3]);
        verify(() => recordVisit(3)).called(1);
      },
    );

    blocTest<QuranReaderCubit, QuranReaderState>(
      'reports a failure with its message and retries the same page',
      build: () {
        when(
          () => getPage(7),
        ).thenAnswer((_) async => const Left(NetworkFailure('لا يوجد إنترنت')));
        return build();
      },
      act: (cubit) async {
        await cubit.goToPage(7);
        expect(cubit.state.status, ReaderStatus.failure);
        expect(cubit.state.errorMessage, 'لا يوجد إنترنت');

        when(() => getPage(7)).thenAnswer((_) async => Right(pageOf(7)));
        await cubit.retry();
      },
      verify: (cubit) {
        expect(cubit.state.status, ReaderStatus.success);
        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.page?.number, 7);
      },
    );

    test('ignores a slow response for a page the user left', () async {
      final slow = Completer<Either<Failure, MushafPage>>();
      when(() => getPage(5)).thenAnswer((_) => slow.future);
      final cubit = build();

      final first = cubit.goToPage(5);
      await cubit.goToPage(6);
      slow.complete(Right(pageOf(5)));
      await first;

      expect(cubit.state.pageNumber, 6);
      expect(cubit.state.page?.number, 6);
      await cubit.close();
    });

    test('clears the selected ayah when the page changes', () async {
      final cubit = build();
      await cubit.goToPage(2);
      cubit.selectAyah('2:1');
      expect(cubit.state.selectedAyahKey, '2:1');

      await cubit.goToPage(3);
      expect(cubit.state.selectedAyahKey, isNull);
      await cubit.close();
    });
  });

  group('navigation helpers', () {
    test('next and previous stop at the Mushaf edges', () async {
      final cubit = build();
      await cubit.goToPage(1);
      await cubit.previousPage();
      expect(cubit.state.pageNumber, 1);

      await cubit.goToPage(604);
      await cubit.nextPage();
      expect(cubit.state.pageNumber, 604);
      await cubit.close();
    });

    test('goToSurah opens its first page', () async {
      final cubit = build();
      await cubit.goToSurah(imran);
      expect(cubit.state.pageNumber, imran.firstPage);
      await cubit.close();
    });

    test('goToJuz opens the juz start page', () async {
      final cubit = build();
      await cubit.goToJuz(2);
      expect(cubit.state.pageNumber, 22);
      await cubit.close();
    });
  });

  group('state', () {
    test('currentSurah follows the first ayah of the page', () async {
      final cubit = build();
      await cubit.init();

      expect(cubit.state.currentSurah, baqarah);
      await cubit.close();
    });

    test('selecting the same ayah twice clears the selection', () {
      final cubit = build();
      cubit.selectAyah('2:5');
      cubit.selectAyah('2:5');
      expect(cubit.state.selectedAyahKey, isNull);
      cubit.close();
    });

    test('toggleBookmark stores the returned progress', () async {
      when(() => toggleBookmark(any())).thenAnswer(
        (_) async => const Right(ReaderProgress(bookmarkedPages: [4])),
      );
      final cubit = build();
      await cubit.goToPage(4);

      await cubit.toggleBookmark();

      expect(cubit.state.isBookmarked, isTrue);
      verify(() => toggleBookmark(4)).called(1);
      await cubit.close();
    });

    test('opening the open panel again closes it', () {
      final cubit = build();
      cubit.openPanel(ReaderPanel.settings);
      expect(cubit.state.panel, ReaderPanel.settings);

      cubit.openPanel(ReaderPanel.navigation);
      expect(cubit.state.panel, ReaderPanel.navigation);

      cubit.openPanel(ReaderPanel.navigation);
      expect(cubit.state.panel, ReaderPanel.none);
      cubit.close();
    });
  });
}
