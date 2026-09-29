import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:manara/features/quran/presentation/pages/quran_reader_page.dart';
import 'package:manara/features/quran/presentation/widgets/mushaf_text.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/quran_fixtures.dart';

class MockQuranReaderCubit extends MockCubit<QuranReaderState>
    implements QuranReaderCubit {}

class MockReaderSettingsCubit extends MockCubit<ReaderSettings>
    implements ReaderSettingsCubit {}

const _mobile = Size(390, 844);
const _tablet = Size(768, 1024);
const _desktop = Size(1440, 900);

void main() {
  late MockQuranReaderCubit reader;
  late MockReaderSettingsCubit settings;

  setUpAll(() {
    registerFallbackValue(ReaderPanel.none);
    registerFallbackValue(ReaderTab.reading);
    registerFallbackValue(fatiha);
  });

  setUp(() {
    reader = MockQuranReaderCubit();
    settings = MockReaderSettingsCubit();
    when(() => settings.state).thenReturn(const ReaderSettings());
    when(() => reader.goToPage(any())).thenAnswer((_) async {});
    when(() => reader.nextPage()).thenAnswer((_) async {});
    when(() => reader.previousPage()).thenAnswer((_) async {});
    when(() => reader.retry()).thenAnswer((_) async {});
    when(() => reader.toggleBookmark()).thenAnswer((_) async {});
  });

  QuranReaderState loaded({
    ReaderPanel panel = ReaderPanel.none,
    ReaderTab tab = ReaderTab.reading,
    ReaderProgress progress = const ReaderProgress(),
    String? selected,
  }) {
    return QuranReaderState(
      status: ReaderStatus.success,
      pageNumber: 2,
      page: pageOf(2),
      surahs: surahs,
      progress: progress,
      panel: panel,
      tab: tab,
      selectedAyahKey: selected,
    );
  }

  Future<void> pump(WidgetTester tester, Size size) {
    return tester.pumpScreen(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranReaderCubit>.value(value: reader),
          BlocProvider<ReaderSettingsCubit>.value(value: settings),
        ],
        child: const QuranReaderView(),
      ),
      size: size,
    );
  }

  group('content', () {
    testWidgets('shows tabs, header, Quran text and pager', (tester) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _mobile);

      for (final tab in ['قراءة', 'تفسير', 'ترجمة', 'ترتيل']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(find.text('سورة البقرة'), findsOneWidget);
      expect(find.text('مدنية | آية 286'), findsOneWidget);
      expect(find.byType(MushafText), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // pager current page
    });

    testWidgets('shows a spinner before the first page arrives', (
      tester,
    ) async {
      when(
        () => reader.state,
      ).thenReturn(const QuranReaderState(status: ReaderStatus.loading));
      await pump(tester, _mobile);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(MushafText), findsNothing);
    });

    testWidgets('shows the error and retries', (tester) async {
      when(() => reader.state).thenReturn(
        QuranReaderState(
          status: ReaderStatus.failure,
          errorMessage: const NetworkFailure().message,
        ),
      );
      await pump(tester, _mobile);

      expect(find.text('تعذّر الاتصال بالإنترنت'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      verify(() => reader.retry()).called(1);
    });

    testWidgets('the other tabs show a coming soon message', (tester) async {
      when(() => reader.state).thenReturn(loaded(tab: ReaderTab.tafsir));
      await pump(tester, _mobile);

      expect(find.text('قريبًا إن شاء الله'), findsOneWidget);
      expect(find.byType(MushafText), findsNothing);
    });

    testWidgets('tapping a tab selects it', (tester) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _mobile);

      await tester.tap(find.text('تفسير'));

      verify(() => reader.selectTab(ReaderTab.tafsir)).called(1);
    });

    testWidgets('the bookmark button toggles the page', (tester) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _mobile);

      await tester.tap(find.byTooltip('حفظ الصفحة'));

      verify(() => reader.toggleBookmark()).called(1);
    });

    testWidgets('a bookmarked page offers to remove it', (tester) async {
      when(() => reader.state).thenReturn(
        loaded(progress: const ReaderProgress(bookmarkedPages: [2])),
      );
      await pump(tester, _mobile);

      expect(find.byTooltip('إزالة من المفضلة'), findsOneWidget);
      expect(find.byTooltip('حفظ الصفحة'), findsNothing);
    });

    testWidgets('the pager jumps to the tapped page', (tester) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _mobile);

      await tester.tap(find.text('4'));

      verify(() => reader.goToPage(4)).called(1);
    });

    testWidgets('swiping left goes to the next page, right to previous', (
      tester,
    ) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _mobile);

      await tester.fling(find.byType(MushafText), const Offset(-300, 0), 1500);
      verify(() => reader.nextPage()).called(1);

      await tester.fling(find.byType(MushafText), const Offset(300, 0), 1500);
      verify(() => reader.previousPage()).called(1);
    });

    testWidgets('the play button says listening is coming', (tester) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _mobile);

      await tester.tap(find.byTooltip('استماع'));
      await tester.pump();

      expect(find.text('ميزة الاستماع قريبًا'), findsOneWidget);
    });
  });

  group('mobile and tablet', () {
    for (final size in [_mobile, _tablet]) {
      testWidgets('navigation opens a bottom sheet at ${size.width}px', (
        tester,
      ) async {
        when(() => reader.state).thenReturn(loaded());
        when(() => reader.goToSurah(any())).thenAnswer((_) async {});
        await pump(tester, size);

        await tester.tap(find.byTooltip('الانتقال إلى'));
        await tester.pumpAndSettle();

        expect(find.text('الانتقال إلى'), findsOneWidget);
        verifyNever(() => reader.openPanel(any()));

        // Choosing a surah navigates and closes the sheet.
        await tester.tap(find.text('آل عمران'));
        await tester.pumpAndSettle();

        verify(() => reader.goToSurah(imran)).called(1);
        expect(find.text('الانتقال إلى'), findsNothing);
      });
    }

    testWidgets('settings opens a bottom sheet and closes with the X', (
      tester,
    ) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _mobile);

      await tester.tap(find.byTooltip('الإعدادات'));
      await tester.pumpAndSettle();
      expect(find.text('حجم الخط'), findsOneWidget);

      await tester.tap(find.byTooltip('إغلاق'));
      await tester.pumpAndSettle();
      expect(find.text('حجم الخط'), findsNothing);
    });
  });

  group('desktop', () {
    testWidgets('the header buttons open the side panels via the cubit', (
      tester,
    ) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _desktop);

      await tester.tap(find.byTooltip('الانتقال إلى'));
      await tester.tap(find.byTooltip('الإعدادات'));

      verify(() => reader.openPanel(ReaderPanel.navigation)).called(1);
      verify(() => reader.openPanel(ReaderPanel.settings)).called(1);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('the navigation panel sits beside the Mushaf', (tester) async {
      when(
        () => reader.state,
      ).thenReturn(loaded(panel: ReaderPanel.navigation));
      await pump(tester, _desktop);

      final panel = tester.getCenter(find.text('الانتقال إلى'));
      final mushaf = tester.getCenter(find.byType(MushafText));
      // Navigation opens on the reading-start (right) side.
      expect(panel.dx, greaterThan(mushaf.dx));
    });

    testWidgets('the settings panel opens on the opposite side', (
      tester,
    ) async {
      when(() => reader.state).thenReturn(loaded(panel: ReaderPanel.settings));
      await pump(tester, _desktop);

      expect(find.text('حجم الخط'), findsOneWidget);
      final panel = tester.getCenter(find.text('حجم الخط'));
      final mushaf = tester.getCenter(find.byType(MushafText));
      expect(panel.dx, lessThan(mushaf.dx));
    });

    testWidgets('the Mushaf card never exceeds 924px', (tester) async {
      when(() => reader.state).thenReturn(loaded());
      await pump(tester, _desktop);

      final width = tester.getSize(find.byType(MushafText)).width;
      expect(width, lessThanOrEqualTo(924));
    });

    testWidgets('closing a panel goes through the cubit', (tester) async {
      when(() => reader.state).thenReturn(loaded(panel: ReaderPanel.settings));
      await pump(tester, _desktop);

      await tester.tap(find.byTooltip('إغلاق'));

      verify(() => reader.closePanel()).called(1);
    });
  });
}
