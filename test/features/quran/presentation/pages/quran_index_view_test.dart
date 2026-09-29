import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/presentation/cubit/quran_index_cubit.dart';
import 'package:manara/features/quran/presentation/pages/quran_index_page.dart';
import 'package:manara/features/quran/presentation/widgets/index/index_side_cards.dart';
import 'package:manara/features/quran/presentation/widgets/index/quran_index_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fonts.dart';
import '../../../../helpers/quran_fixtures.dart';

class MockQuranIndexCubit extends MockCubit<QuranIndexState>
    implements QuranIndexCubit {}

const _desktop = Size(1440, 1129);
const _mobile = Size(390, 1800);

/// 30 surahs so the grid has more than one page of cards.
final _surahs = [
  for (var i = 1; i <= 30; i++)
    Surah(
      id: i,
      nameArabic: 'سورة$i',
      revelationPlace: RevelationPlace.makkah,
      versesCount: 7,
      firstPage: i * 2,
      lastPage: i * 2 + 1,
    ),
];

void main() {
  late MockQuranIndexCubit cubit;

  QuranIndexState loaded({
    QuranIndexTab tab = QuranIndexTab.surahs,
    ReaderProgress progress = const ReaderProgress(),
    LastReadPosition? lastRead,
  }) {
    return QuranIndexState(
      status: QuranIndexStatus.success,
      surahs: _surahs,
      progress: progress,
      today: DateTime(2026, 9, 29),
      lastRead: lastRead,
      tab: tab,
    );
  }

  setUp(() {
    cubit = MockQuranIndexCubit();
    when(() => cubit.state).thenReturn(loaded());
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: AppRoutes.quran,
      routes: [
        GoRoute(
          path: AppRoutes.quran,
          builder: (_, _) => BlocProvider<QuranIndexCubit>.value(
            value: cubit,
            child: const QuranIndexView(),
          ),
          routes: [
            GoRoute(
              path: 'read',
              builder: (_, state) => Scaffold(
                body: Text('READER ${state.uri.queryParameters['page']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    );
    await tester.pump();
  }

  group('desktop (Figma 1440)', () {
    testWidgets('lays out the design: search, tabs, side column, grid', (
      tester,
    ) async {
      await pump(tester, _desktop);

      for (final text in [
        'السور',
        'الأجزاء',
        'قرئ مؤخراً',
        'المفضلة',
        'وردي اليومي',
        'مواصلة القراءة',
        'السور الأكثر قراءة',
        'عرض المزيد',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(tester.takeException(), isNull);

      // First page of cards, four per row at Figma's positions.
      expect(find.byType(QuranIndexCard), findsNWidgets(24));
      final first = tester.getRect(find.byType(QuranIndexCard).first);
      expect(first.right, closeTo(1440 - 60 - 320 - 46, 1));
      expect(first.top, closeTo(97 + 44 + 44 + 35, 1));
      expect(first.height, QuranIndexCard.height);
      expect(first.width, closeTo(225.5, 1));

      final wird = tester.getRect(find.byType(DailyWirdCard));
      expect(wird.left, closeTo(1060, 1));
      expect(wird.width, 320);
    });

    testWidgets('"عرض المزيد" asks for more cards', (tester) async {
      await pump(tester, _desktop);

      await tester.ensureVisible(find.text('عرض المزيد'));
      await tester.tap(find.text('عرض المزيد'));

      verify(() => cubit.showMore()).called(1);
    });

    testWidgets('a surah card opens the reader at its first page', (
      tester,
    ) async {
      await pump(tester, _desktop);

      await tester.tap(find.text('سورة3'));
      await tester.pumpAndSettle();

      expect(find.text('READER 6'), findsOneWidget);
    });

    testWidgets('coming back from the reader refreshes the progress', (
      tester,
    ) async {
      when(() => cubit.refreshProgress()).thenAnswer((_) async {});
      await pump(tester, _desktop);

      await tester.tap(find.text('سورة3'));
      await tester.pumpAndSettle();
      verifyNever(() => cubit.refreshProgress());

      GoRouter.of(tester.element(find.text('READER 6'))).go(AppRoutes.quran);
      await tester.pumpAndSettle();

      verify(() => cubit.refreshProgress()).called(1);
    });

    testWidgets('continue reading shows where reading stopped', (tester) async {
      when(() => cubit.state).thenReturn(
        loaded(
          progress: const ReaderProgress(lastPage: 3, recentPages: [3]),
          lastRead: const LastReadPosition(surah: baqarah, ayahNumber: 6),
        ),
      );
      await pump(tester, _desktop);

      expect(find.text('سورة البقرة'), findsOneWidget);
      expect(find.text('الآية 6'), findsOneWidget);

      await tester.tap(find.text('متابعة القراءة'));
      await tester.pumpAndSettle();
      expect(find.text('READER null'), findsOneWidget);
    });

    testWidgets('tabs switch through the cubit', (tester) async {
      await pump(tester, _desktop);

      await tester.tap(find.text('الأجزاء'));

      verify(() => cubit.selectTab(QuranIndexTab.juz)).called(1);
    });

    testWidgets('the juz tab lists all thirty', (tester) async {
      when(() => cubit.state).thenReturn(loaded(tab: QuranIndexTab.juz));
      await pump(tester, _desktop);

      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(find.byType(QuranIndexCard), findsNWidgets(24));
      expect(find.text('عرض المزيد'), findsOneWidget);
    });

    testWidgets('favorites list saved pages, newest first', (tester) async {
      when(() => cubit.state).thenReturn(
        loaded(
          tab: QuranIndexTab.favorites,
          progress: const ReaderProgress(bookmarkedPages: [4, 10]),
        ),
      );
      await pump(tester, _desktop);

      final cards = tester
          .widgetList<QuranIndexCard>(find.byType(QuranIndexCard))
          .toList();
      expect(cards.map((c) => c.number), [10, 4]);
      expect(cards.first.title, 'سورة سورة5');
      expect(find.text('عرض المزيد'), findsNothing);
    });

    testWidgets('empty favorites explain how to add one', (tester) async {
      when(() => cubit.state).thenReturn(loaded(tab: QuranIndexTab.favorites));
      await pump(tester, _desktop);

      expect(find.textContaining('لا توجد صفحات في المفضلة'), findsOneWidget);
    });

    testWidgets('typing searches through the cubit', (tester) async {
      await pump(tester, _desktop);

      await tester.enterText(find.byType(TextField), 'يس');

      verify(() => cubit.search('يس')).called(1);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const QuranIndexState(status: QuranIndexStatus.failure));
      when(() => cubit.load()).thenAnswer((_) async {});
      await pump(tester, _desktop);

      await tester.tap(find.text('إعادة المحاولة'));

      verify(() => cubit.load()).called(1);
    });
  });

  group('mobile', () {
    testWidgets('stacks the sections with two cards per row', (tester) async {
      await pump(tester, _mobile);

      expect(tester.takeException(), isNull);
      final cards = find.byType(QuranIndexCard);
      final a = tester.getRect(cards.at(0));
      final b = tester.getRect(cards.at(1));
      final c = tester.getRect(cards.at(2));
      expect(a.top, b.top);
      expect(c.top, greaterThan(a.bottom));
      expect(a.right, closeTo(390 - 16, 1));
      expect(b.left, closeTo(16, 1));

      expect(
        tester.getRect(find.byType(DailyWirdCard)).bottom,
        lessThan(a.top),
      );
    });
  });
}
