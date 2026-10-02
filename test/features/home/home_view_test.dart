import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';
import 'package:manara/features/home/presentation/cubit/home_cubit.dart';
import 'package:manara/features/home/presentation/pages/home_page.dart';
import 'package:manara/features/home/presentation/widgets/daily_adhkar_card.dart';
import 'package:manara/features/home/presentation/widgets/hadith_of_day_card.dart';
import 'package:manara/features/home/presentation/widgets/prayer_times_card.dart';
import 'package:manara/features/home/presentation/widgets/reading_journey_card.dart';
import 'package:manara/features/prayer/data/models/prayer_times_model.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fonts.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockPrayerTimesCubit extends MockCubit<PrayerTimesState>
    implements PrayerTimesCubit {}

const _desktop = Size(1440, 3098);
const _mobile = Size(390, 4200);

const _hadith = Hadith(
  text: 'مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ',
  source: 'رواه مسلم',
);

/// 16:00 on the day of the fixture: Asr (16:10) is next.
DateTime _clock() => DateTime(2026, 9, 29, 16);

PrayerTimesModel _times() => PrayerTimesModel.fromJson(
  {
    'timings': {
      'Fajr': '05:21',
      'Sunrise': '06:47',
      'Dhuhr': '12:45',
      'Asr': '16:10',
      'Maghrib': '18:43',
      'Isha': '20:00',
    },
    'date': {
      'hijri': {
        'day': '18',
        'month': {'ar': 'ربيع الثاني'},
        'year': '1448',
      },
    },
  },
  date: DateTime(2026, 9, 29),
  location: PrayerLocation.cairo,
);

void main() {
  late MockHomeCubit home;
  late MockPrayerTimesCubit prayer;

  setUp(() {
    home = MockHomeCubit();
    prayer = MockPrayerTimesCubit();
    when(() => home.state).thenReturn(
      const HomeState(
        hadith: _hadith,
        progress: ReaderProgress(lastPage: 222, recentPages: [222]),
        streak: 7,
      ),
    );
    when(() => prayer.state).thenReturn(
      PrayerTimesState(status: PrayerTimesStatus.success, times: _times()),
    );
    when(() => prayer.load()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<HomeCubit>.value(value: home),
              BlocProvider<PrayerTimesCubit>.value(value: prayer),
            ],
            child: const HomeView(clock: _clock),
          ),
        ),
        GoRoute(
          path: AppRoutes.quran,
          builder: (_, _) => const Scaffold(body: Text('QURAN PAGE')),
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
    testWidgets('shows every section of the design', (tester) async {
      await pump(tester, _desktop);

      for (final text in [
        'مرحبًا بك في منارة',
        'الوصول السريع',
        'حديث اليوم',
        'الصلاة القادمة',
        'أذكارك اليومية',
        'رحلتك في منارة',
        'كنوز منارة',
        'المحفوظات',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('cards render at their exact Figma sizes', (tester) async {
      await pump(tester, _desktop);

      Size sizeOf(Type card) => tester.getSize(
        find.descendant(
          of: find.byType(card),
          matching: find.byType(DesignBox),
        ),
      );

      expect(sizeOf(PrayerTimesCard), PrayerTimesCard.designSize);
      expect(sizeOf(HadithOfDayCard), HadithOfDayCard.designSize);
      expect(sizeOf(DailyAdhkarCard), DailyAdhkarCard.designSize);
      expect(sizeOf(ReadingJourneyCard), ReadingJourneyCard.designSize);
    });

    testWidgets('cards sit side by side in reading order', (tester) async {
      await pump(tester, _desktop);

      double x(Type t) => tester.getCenter(find.byType(t)).dx;
      expect(x(HadithOfDayCard), greaterThan(x(PrayerTimesCard)));
      expect(x(DailyAdhkarCard), greaterThan(x(ReadingJourneyCard)));
      expect(
        tester.getTopLeft(find.byType(PrayerTimesCard)).dx,
        closeTo(36, 1),
      );
    });

    testWidgets('the prayer card counts down to the next prayer', (
      tester,
    ) async {
      await pump(tester, _desktop);

      expect(find.text('00 : 10 : 00'), findsOneWidget);
      expect(find.text('04:10 PM'), findsOneWidget);
      // "العصر" appears in the list and as the next prayer.
      expect(find.text('العصر'), findsNWidgets(2));

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the journey card shows the juz and streak', (tester) async {
      await pump(tester, _desktop);

      expect(find.text('12'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('7 أيام على التوالي'), findsOneWidget);
    });

    testWidgets('the hero button opens the Quran reader', (tester) async {
      await pump(tester, _desktop);

      await tester.tap(find.text('ابدأ رحلتك الآن'));
      await tester.pumpAndSettle();

      expect(find.text('QURAN PAGE'), findsOneWidget);
    });

    testWidgets('the Quran quick card opens the reader', (tester) async {
      await pump(tester, _desktop);

      await tester.tap(find.text('اقرأ واستمع وتدبّر'));
      await tester.pumpAndSettle();

      expect(find.text('QURAN PAGE'), findsOneWidget);
    });

    testWidgets('sections that are not built yet say so', (tester) async {
      await pump(tester, _desktop);

      await tester.tap(find.text('اعرف اتجاه القبلة'));
      await tester.pump();

      expect(find.text('قريبًا إن شاء الله'), findsOneWidget);
    });

    testWidgets('copying the hadith puts it on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(tester, _desktop);

      await tester.tap(find.byTooltip('نسخ الحديث'));
      await tester.pump();

      expect(copied, contains(_hadith.text));
      expect(copied, contains('رواه مسلم'));
      expect(find.text('تم نسخ الحديث'), findsOneWidget);
    });

    testWidgets('a failed prayer load offers a retry', (tester) async {
      when(() => prayer.state).thenReturn(
        const PrayerTimesState(
          status: PrayerTimesStatus.failure,
          errorMessage: 'offline',
        ),
      );
      await pump(tester, _desktop);

      expect(find.text('تعذّر تحميل المواقيت'), findsOneWidget);
      expect(find.text('--:--'), findsNWidgets(6));
      await tester.tap(find.text('إعادة المحاولة'));

      verify(() => prayer.load()).called(1);
    });
  });

  // Android builds the first frame at width 0, before the window metrics
  // arrive; no section may compute a negative size there.
  testWidgets('survives the zero-width first frame, then lays out', (
    tester,
  ) async {
    await pump(tester, const Size(0, 800));
    expect(tester.takeException(), isNull);

    await pump(tester, _mobile);
    expect(tester.takeException(), isNull);
    expect(find.text('كنوز منارة'), findsOneWidget);
  });

  // Many phones ship with a larger system font; fixed-size cards must
  // still fit their content.
  testWidgets('quick access cards fit a larger system font', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester, _mobile);

    expect(tester.takeException(), isNull);
  });

  group('mobile', () {
    testWidgets('stacks the cards and uses the compact layouts', (
      tester,
    ) async {
      await pump(tester, _mobile);

      expect(tester.takeException(), isNull);
      // Compact layouts do not use the fixed design canvas.
      for (final card in [PrayerTimesCard, HadithOfDayCard, DailyAdhkarCard]) {
        expect(
          find.descendant(
            of: find.byType(card),
            matching: find.byType(DesignBox),
          ),
          findsNothing,
        );
        expect(tester.getSize(find.byType(card)).width, lessThanOrEqualTo(358));
      }
      expect(
        tester.getCenter(find.byType(HadithOfDayCard)).dy,
        lessThan(tester.getCenter(find.byType(PrayerTimesCard)).dy),
      );
      expect(find.text('الصلاة القادمة'), findsOneWidget);
    });

    testWidgets('the navigation links move into a drawer', (tester) async {
      await pump(tester, _mobile);

      expect(find.text('الغرف'), findsNothing);
      await tester.tap(find.byTooltip('القائمة'));
      await tester.pumpAndSettle();

      expect(find.text('الغرف'), findsOneWidget);
      await tester.tap(find.text('القرآن الكريم').last);
      await tester.pumpAndSettle();

      expect(find.text('QURAN PAGE'), findsOneWidget);
    });
  });

  group('wording', () {
    test('streak label follows Arabic number agreement', () {
      expect(ReadingJourneyCard.streakLabel(0), 'ابدأ رحلتك اليوم');
      expect(ReadingJourneyCard.streakLabel(1), 'يوم واحد على التوالي');
      expect(ReadingJourneyCard.streakLabel(2), 'يومان على التوالي');
      expect(ReadingJourneyCard.streakLabel(7), '7 أيام على التوالي');
      expect(ReadingJourneyCard.streakLabel(15), '15 يومًا على التوالي');
    });

    test('adhkar switch from morning to evening in the afternoon', () {
      expect(AdhkarPeriod.of(DateTime(2026, 1, 1, 8)), AdhkarPeriod.morning);
      expect(
        AdhkarPeriod.of(DateTime(2026, 1, 1, 14, 59)),
        AdhkarPeriod.morning,
      );
      expect(AdhkarPeriod.of(DateTime(2026, 1, 1, 15)), AdhkarPeriod.evening);
      expect(AdhkarPeriod.of(DateTime(2026, 1, 1, 2)), AdhkarPeriod.evening);
    });
  });
}
