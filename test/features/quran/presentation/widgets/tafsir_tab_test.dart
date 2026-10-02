import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/tafsir_cubit.dart';
import 'package:manara/features/quran/presentation/pages/quran_reader_page.dart';
import 'package:manara/features/quran/presentation/widgets/mushaf_text.dart';
import 'package:manara/features/quran/presentation/widgets/tafsir_content.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/quran_fixtures.dart';

class MockQuranReaderCubit extends MockCubit<QuranReaderState>
    implements QuranReaderCubit {}

class MockReaderSettingsCubit extends MockCubit<ReaderSettings>
    implements ReaderSettingsCubit {}

class MockTafsirCubit extends MockCubit<TafsirState> implements TafsirCubit {}

const _mobile = Size(390, 844);
const _desktop = Size(1440, 900);

void main() {
  late MockQuranReaderCubit reader;
  late MockReaderSettingsCubit settings;
  late MockTafsirCubit tafsir;

  final page3 = pageOf(3, firstAyah: 6); // 2:6, 2:7, 2:8

  final sections = [
    TafsirSection(ayahs: [page3.ayahs[0]], paragraphs: const [mukhtasar2v6]),
    // 2:7 and 2:8 explained together.
    TafsirSection(
      ayahs: [page3.ayahs[1], page3.ayahs[2]],
      paragraphs: const ['الفقرة الأولى', 'الفقرة الثانية'],
    ),
  ];

  setUpAll(() {
    registerFallbackValue(pageOf(1));
    registerFallbackValue(TafsirSource.mukhtasar);
  });

  QuranReaderState readerState({
    ReaderTab tab = ReaderTab.tafsir,
    MushafPage? page,
  }) {
    final current = page ?? page3;
    return QuranReaderState(
      status: ReaderStatus.success,
      pageNumber: current.number,
      page: current,
      surahs: surahs,
      tab: tab,
    );
  }

  TafsirState loadedTafsir([List<TafsirSection>? content]) => TafsirState(
    status: TafsirStatus.success,
    pageNumber: 3,
    sections: content ?? sections,
  );

  setUp(() {
    reader = MockQuranReaderCubit();
    settings = MockReaderSettingsCubit();
    tafsir = MockTafsirCubit();
    when(() => settings.state).thenReturn(const ReaderSettings());
    when(() => reader.state).thenReturn(readerState());
    when(() => reader.nextPage()).thenAnswer((_) async {});
    when(() => reader.previousPage()).thenAnswer((_) async {});
    when(() => reader.toggleBookmark()).thenAnswer((_) async {});
    when(() => tafsir.state).thenReturn(loadedTafsir());
    when(() => tafsir.load(any())).thenAnswer((_) async {});
    when(() => tafsir.selectSource(any())).thenAnswer((_) async {});
    when(() => tafsir.retry()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, [Size size = _mobile]) {
    return tester.pumpScreen(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranReaderCubit>.value(value: reader),
          BlocProvider<ReaderSettingsCubit>.value(value: settings),
          BlocProvider<TafsirCubit>.value(value: tafsir),
        ],
        child: const QuranReaderView(),
      ),
      size: size,
    );
  }

  for (final (name, size) in [('mobile', _mobile), ('desktop', _desktop)]) {
    group(name, () {
      testWidgets('each ayah, with its ﴿n﴾ marker, comes before its tafsir', (
        tester,
      ) async {
        await pump(tester, size);

        final ayah = find.text('نص الآية 6\u00A0﴿٦﴾');
        final text = find.text(mukhtasar2v6);
        expect(ayah, findsOneWidget);
        expect(text, findsOneWidget);
        expect(
          tester.getTopLeft(text).dy,
          greaterThan(tester.getBottomLeft(ayah).dy - 1),
        );
        expect(find.byType(MushafText), findsNothing);
        expect(tester.takeException(), isNull);
        verify(() => tafsir.load(page3)).called(1);
      });

      testWidgets('ayahs explained together show their tafsir once', (
        tester,
      ) async {
        await pump(tester, size);

        expect(
          find.text('نص الآية 7\u00A0﴿٧﴾ نص الآية 8\u00A0﴿٨﴾'),
          findsOneWidget,
        );
        expect(find.text('الفقرة الأولى'), findsOneWidget);
        expect(find.text('الفقرة الثانية'), findsOneWidget);
      });

      testWidgets('the header swaps play for the tafsir picker', (
        tester,
      ) async {
        await pump(tester, size);

        expect(find.text('المختصر'), findsOneWidget);
        expect(find.byTooltip('استماع'), findsNothing);
        expect(find.text('سورة البقرة'), findsOneWidget);
        expect(find.byTooltip('حفظ الصفحة'), findsOneWidget);
      });

      testWidgets('names the source after the tafsir', (tester) async {
        await pump(tester, size);
        await tester.scrollUntilVisible(
          find.textContaining('المصدر:'),
          200,
          scrollable: find.descendant(
            of: find.byType(TafsirContent),
            matching: find.byType(Scrollable),
          ),
        );

        expect(
          find.text('المصدر: ${TafsirSource.mukhtasar.reference}'),
          findsOneWidget,
        );
      });
    });
  }

  // Android builds the first frame at width 0.
  testWidgets('survives the zero-width first frame', (tester) async {
    await pump(tester, const Size(0, 800));
    expect(tester.takeException(), isNull);

    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(mukhtasar2v6), findsOneWidget);
  });

  testWidgets('fits a larger system font on mobile', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester);
    await tester.tap(find.text('المختصر'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('tafsir text is larger on desktop than on mobile', (
    tester,
  ) async {
    double size() =>
        tester.widget<Text>(find.text(mukhtasar2v6)).style!.fontSize!;

    await pump(tester);
    final mobile = size();
    await pump(tester, _desktop);

    expect(mobile, 17);
    expect(size(), 24);
  });

  testWidgets('the picker lists the books and selects one', (tester) async {
    await pump(tester);

    await tester.tap(find.text('المختصر'));
    await tester.pumpAndSettle();

    expect(find.text('نوع التفسير'), findsOneWidget);
    expect(find.text('ابن كثير'), findsOneWidget);

    await tester.tap(find.text('ابن كثير'));
    await tester.pumpAndSettle();

    verify(() => tafsir.selectSource(TafsirSource.ibnKathir)).called(1);
    expect(find.text('نوع التفسير'), findsNothing);
  });

  testWidgets('choosing the selected book again changes nothing', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('المختصر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المختصر').last);
    await tester.pumpAndSettle();

    verifyNever(() => tafsir.selectSource(any()));
  });

  testWidgets('the reading tab keeps the play button', (tester) async {
    when(() => reader.state).thenReturn(readerState(tab: ReaderTab.reading));
    await pump(tester);

    expect(find.byTooltip('استماع'), findsOneWidget);
    expect(find.text('المختصر'), findsNothing);
  });

  testWidgets('shows a spinner until the first tafsir arrives', (tester) async {
    when(() => tafsir.state).thenReturn(
      const TafsirState(status: TafsirStatus.loading, pageNumber: 3),
    );
    await pump(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('dims the old page while the next one loads', (tester) async {
    when(
      () => tafsir.state,
    ).thenReturn(loadedTafsir().copyWith(status: TafsirStatus.loading));
    await pump(tester);

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text(mukhtasar2v6), findsOneWidget);
  });

  testWidgets('a failure shows the message and retries', (tester) async {
    when(() => tafsir.state).thenReturn(
      TafsirState(
        status: TafsirStatus.failure,
        pageNumber: 3,
        errorMessage: const NetworkFailure().message,
      ),
    );
    await pump(tester);

    expect(find.text('تعذّر الاتصال بالإنترنت'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));

    verify(() => tafsir.retry()).called(1);
  });

  testWidgets('follows the reader to a new page', (tester) async {
    final page4 = pageOf(4, firstAyah: 17);
    whenListen(
      reader,
      Stream.value(readerState(page: page4)),
      initialState: readerState(),
    );
    await pump(tester);
    await tester.pump();

    verify(() => tafsir.load(page3)).called(1);
    verify(() => tafsir.load(page4)).called(1);
  });

  testWidgets('a new surah starts with its banner', (tester) async {
    final imranStart = ayah(3, 1, page: 50);
    when(() => tafsir.state).thenReturn(
      loadedTafsir([
        TafsirSection(ayahs: [imranStart], paragraphs: const ['تفسير']),
      ]),
    );
    await pump(tester);

    expect(find.text('سُورَةُ آل عمران'), findsOneWidget);
  });

  testWidgets('swiping turns the page', (tester) async {
    await pump(tester);

    await tester.fling(find.byType(TafsirContent), const Offset(-300, 0), 1500);
    verify(() => reader.nextPage()).called(1);

    await tester.fling(find.byType(TafsirContent), const Offset(300, 0), 1500);
    verify(() => reader.previousPage()).called(1);
  });

  testWidgets('the bookmark toggles the page', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('حفظ الصفحة'));

    verify(() => reader.toggleBookmark()).called(1);
  });
}
