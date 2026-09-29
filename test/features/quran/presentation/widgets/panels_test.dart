import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:manara/features/quran/presentation/widgets/navigation_panel.dart';
import 'package:manara/features/quran/presentation/widgets/settings_panel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/quran_fixtures.dart';

class MockQuranReaderCubit extends MockCubit<QuranReaderState>
    implements QuranReaderCubit {}

class MockReaderSettingsCubit extends MockCubit<ReaderSettings>
    implements ReaderSettingsCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(fatiha);
    registerFallbackValue(LineSpacing.normal);
    registerFallbackValue(MushafFont.amiri);
  });

  group('NavigationPanel', () {
    late MockQuranReaderCubit cubit;
    var closed = 0;
    var navigated = 0;

    setUp(() {
      cubit = MockQuranReaderCubit();
      closed = 0;
      navigated = 0;
      when(() => cubit.goToSurah(any())).thenAnswer((_) async {});
      when(() => cubit.goToJuz(any())).thenAnswer((_) async {});
      when(() => cubit.goToPage(any())).thenAnswer((_) async {});
    });

    Future<void> pump(
      WidgetTester tester, {
      ReaderProgress progress = const ReaderProgress(),
    }) async {
      when(() => cubit.state).thenReturn(
        QuranReaderState(
          status: ReaderStatus.success,
          pageNumber: 2,
          page: pageOf(2),
          surahs: surahs,
          progress: progress,
        ),
      );
      await tester.pumpScreen(
        Scaffold(
          body: BlocProvider<QuranReaderCubit>.value(
            value: cubit,
            child: NavigationPanel(
              onClose: () => closed++,
              onNavigated: () => navigated++,
            ),
          ),
        ),
        size: const Size(500, 1600),
      );
    }

    testWidgets('lists the surahs with Figma style subtitles', (tester) async {
      await pump(tester);

      expect(find.text('الانتقال إلى'), findsOneWidget);
      expect(find.text('الفاتحة'), findsOneWidget);
      expect(find.text('مكية – 7 آيات'), findsOneWidget);
      expect(find.text('مدنية – 286 آية'), findsOneWidget);
    });

    testWidgets('close button calls onClose', (tester) async {
      await pump(tester);

      await tester.tap(find.byTooltip('إغلاق'));
      expect(closed, 1);
    });

    testWidgets('choosing a surah navigates and notifies', (tester) async {
      await pump(tester);

      await tester.tap(find.text('آل عمران'));

      verify(() => cubit.goToSurah(imran)).called(1);
      expect(navigated, 1);
    });

    testWidgets('search ignores diacritics and letter variants', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'بقره');
      await tester.pump();

      expect(find.text('البقرة'), findsOneWidget);
      expect(find.text('الفاتحة'), findsNothing);
      expect(find.text('الأجزاء'), findsNothing);
    });

    testWidgets('search shows an empty state when nothing matches', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump();

      expect(find.text('لا توجد نتائج'), findsOneWidget);
    });

    testWidgets('juz list jumps to the chosen juz', (tester) async {
      await pump(tester);

      await tester.tap(find.text('الأجزاء'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الجزء 2'));

      verify(() => cubit.goToJuz(2)).called(1);
    });

    testWidgets('page jump validates the range', (tester) async {
      await pump(tester);
      await tester.tap(find.text('الصفحات'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '700');
      await tester.tap(find.text('انتقال'));
      await tester.pump();

      expect(find.textContaining('أدخل رقمًا'), findsOneWidget);
      verifyNever(() => cubit.goToPage(any()));

      await tester.enterText(find.byType(TextField).last, '300');
      await tester.tap(find.text('انتقال'));
      await tester.pump();

      verify(() => cubit.goToPage(300)).called(1);
      expect(find.textContaining('أدخل رقمًا'), findsNothing);
    });

    testWidgets('recent pages show the surah they belong to', (tester) async {
      await pump(tester, progress: const ReaderProgress(recentPages: [60, 2]));

      await tester.tap(find.text('قُرئ مؤخرًا'));
      await tester.pumpAndSettle();

      expect(find.text('صفحة 60'), findsOneWidget);
      expect(find.text('سورة آل عمران'), findsOneWidget);
      await tester.tap(find.text('صفحة 2'));
      verify(() => cubit.goToPage(2)).called(1);
    });

    testWidgets('favorites and recents show empty messages', (tester) async {
      await pump(tester);

      await tester.tap(find.text('المفضلة'));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد صفحات محفوظة'), findsOneWidget);
    });
  });

  group('SettingsPanel', () {
    late MockReaderSettingsCubit cubit;
    var closed = 0;

    setUp(() {
      cubit = MockReaderSettingsCubit();
      closed = 0;
      when(() => cubit.state).thenReturn(const ReaderSettings());
      when(() => cubit.setFontScale(any())).thenAnswer((_) async {});
      when(() => cubit.setLineSpacing(any())).thenAnswer((_) async {});
      when(() => cubit.setFont(any())).thenAnswer((_) async {});
      when(() => cubit.setTextColor(any())).thenAnswer((_) async {});
      when(() => cubit.setBackgroundColor(any())).thenAnswer((_) async {});
      when(() => cubit.setShowStopMarks(any())).thenAnswer((_) async {});
      when(() => cubit.setShowTashkeel(any())).thenAnswer((_) async {});
      when(
        () => cubit.setHighlightWhilePlaying(any()),
      ).thenAnswer((_) async {});
    });

    Future<void> pump(WidgetTester tester) {
      return tester.pumpScreen(
        Scaffold(
          body: BlocProvider<ReaderSettingsCubit>.value(
            value: cubit,
            child: SettingsPanel(onClose: () => closed++),
          ),
        ),
        size: const Size(500, 1400),
      );
    }

    testWidgets('shows every Figma section', (tester) async {
      await pump(tester);

      for (final label in [
        'الإعدادات',
        'خط المصحف',
        'حجم الخط',
        'تباعد الأسطر',
        'لون الخط',
        'لون الخلفية',
        'إظهار علامات الوقف',
        'إظهار التشكيل',
        'تظليل الآية أثناء التلاوة',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // The night mode from Figma was dropped on purpose.
      expect(find.text('وضع القراءة'), findsNothing);
      expect(find.text('ليلي'), findsNothing);
    });

    testWidgets('close button calls onClose', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('إغلاق'));
      expect(closed, 1);
    });

    testWidgets('toggling a checkbox row saves the opposite value', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('إظهار التشكيل'));
      await tester.tap(find.text('إظهار علامات الوقف'));
      await tester.tap(find.text('تظليل الآية أثناء التلاوة'));

      verify(() => cubit.setShowTashkeel(false)).called(1);
      verify(() => cubit.setShowStopMarks(false)).called(1);
      verify(() => cubit.setHighlightWhilePlaying(false)).called(1);
    });

    testWidgets('choosing a line spacing option saves it', (tester) async {
      await pump(tester);

      await tester.tap(find.text('عادي'));
      await tester.tap(find.text('متوسط'));

      verify(() => cubit.setLineSpacing(LineSpacing.normal)).called(1);
      verify(() => cubit.setLineSpacing(LineSpacing.medium)).called(1);
    });

    testWidgets('choosing a color saves its index', (tester) async {
      await pump(tester);

      // The first color of each row is selected; tap the fourth one.
      final swatches = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label ?? '').startsWith('لون '),
      );
      expect(swatches, findsNWidgets(12));
      await tester.tap(swatches.at(3));
      await tester.tap(swatches.at(8));

      verify(() => cubit.setTextColor(3)).called(1);
      verify(() => cubit.setBackgroundColor(2)).called(1);
    });

    testWidgets('moving the slider saves the font scale', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(Slider));

      verify(() => cubit.setFontScale(any())).called(1);
    });

    testWidgets('the current font is marked as selected', (tester) async {
      await pump(tester);

      expect(find.text('الخط الأميري'), findsOneWidget);
      await tester.tap(find.text('الخط الأميري'));
      verify(() => cubit.setFont(MushafFont.amiri)).called(1);
    });
  });

  test('Surah fallback value is registered', () {
    expect(fatiha.revelationPlace, RevelationPlace.makkah);
  });
}
