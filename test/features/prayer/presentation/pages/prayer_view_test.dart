import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/app_images.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/prayer/presentation/cubit/device_location_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/pages/prayer_page.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';
import 'package:manara/features/prayer/presentation/widgets/times/qibla_section.dart';
import 'package:manara/features/prayer/presentation/widgets/times/today_panel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fonts.dart';
import '../../../../helpers/prayer_fixtures.dart';

class MockPrayerTimesCubit extends MockCubit<PrayerTimesState>
    implements PrayerTimesCubit {}

class MockNearbyCitiesCubit extends MockCubit<NearbyCitiesState>
    implements NearbyCitiesCubit {}

class MockDeviceLocationCubit extends MockCubit<DeviceLocationState>
    implements DeviceLocationCubit {}

const _desktop = Size(1440, 2600);
const _mobile = Size(390, 4200);

/// From assets/data/cities.json (GeoNames 360995).
const _giza = PrayerLocation(
  id: 360995,
  name: 'الجيزة',
  nameEn: 'Giza',
  country: 'مصر',
  countryCode: 'EG',
  latitude: 30.00944,
  longitude: 31.20861,
  timeZone: 'Africa/Cairo',
);

PrayerTimes _withFetchedAt(PrayerTimes t, DateTime fetchedAt) => PrayerTimes(
  location: t.location,
  today: t.today,
  tomorrow: t.tomorrow,
  fetchedAt: fetchedAt,
);

void main() {
  late MockPrayerTimesCubit prayer;
  late MockNearbyCitiesCubit nearby;
  late MockDeviceLocationCubit device;

  /// 13:00 in Cairo on 2 Oct 2026: Asr (16:08) is next, 3 h 8 min away.
  var now = cairo(10, 2, 13);

  setUpAll(() => registerFallbackValue(PrayerLocation.cairo));

  setUp(() {
    now = cairo(10, 2, 13);
    prayer = MockPrayerTimesCubit();
    nearby = MockNearbyCitiesCubit();
    device = MockDeviceLocationCubit();
    when(() => device.state).thenReturn(const DeviceLocationState());
    when(() => device.locate()).thenAnswer((_) async {});
    when(() => prayer.state).thenReturn(
      PrayerTimesState(
        status: PrayerTimesStatus.success,
        times: cairoTimes(10, 2),
      ),
    );
    when(() => prayer.load()).thenAnswer((_) async {});
    when(() => prayer.retry()).thenAnswer((_) async {});
    when(() => prayer.refreshIfStale()).thenAnswer((_) async {});
    when(() => prayer.changeLocation(any())).thenAnswer((_) async {});
    when(() => nearby.state).thenReturn(
      const NearbyCitiesState(
        from: PrayerLocation.cairo,
        cities: [CityDistance(_giza, 7.11)],
      ),
    );
    when(() => nearby.load(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    PrayerTab tab = PrayerTab.times,
  }) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget page(PrayerTab t) => MultiBlocProvider(
      providers: [
        BlocProvider<PrayerTimesCubit>.value(value: prayer),
        BlocProvider<NearbyCitiesCubit>.value(value: nearby),
        BlocProvider<DeviceLocationCubit>.value(value: device),
      ],
      child: PrayerView(tab: t, clock: () => now),
    );

    final router = GoRouter(
      initialLocation: tab.route,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('HOME')),
        GoRoute(
          path: AppRoutes.prayer,
          builder: (_, _) => page(PrayerTab.times),
          routes: [
            GoRoute(
              path: 'monthly',
              builder: (_, _) => page(PrayerTab.monthly),
            ),
            GoRoute(path: 'alerts', builder: (_, _) => page(PrayerTab.alerts)),
            GoRoute(
              path: 'settings',
              builder: (_, state) => Text('SETTINGS ${state.uri.query}'),
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

  group('times tab, desktop 1440', () {
    testWidgets('shows every part of the design', (tester) async {
      await pump(tester, _desktop);

      for (final text in [
        'القاهرة',
        'الجمعة، 2 أكتوبر 2026 · 21 ربيع الثاني 1448 هـ',
        'المواقيت و القبلة',
        'الجدول الشهري',
        'التنبيهات',
        'الإعدادات',
        'مواقيت الصلاة',
        'الصلاة القادمة',
        'مدن قريبة',
        'اتجاه القبلة – كيف تجد اتجاه الكعبة',
        'الهيئة المصرية العامة للمساحة',
        'Africa/Cairo',
        '30.0626, 31.2497',
        '11 ساعة 50 دقيقة',
        '1,288 km',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the main panel keeps the Figma size', (tester) async {
      await pump(tester, _desktop);
      expect(
        tester.getSize(
          find.descendant(
            of: find.byType(TodayPanel),
            matching: find.byType(DesignBox),
          ),
        ),
        TodayPanel.designSize,
      );
    });

    testWidgets('shows the mosque at its Figma size on desktop only', (
      tester,
    ) async {
      final mosque = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == AppImages.prayerMosque,
      );

      await pump(tester, _desktop);
      expect(mosque, findsOneWidget);
      expect(tester.getSize(mosque), const Size(593, 465));

      await pump(tester, _mobile);
      expect(mosque, findsNothing);
    });

    testWidgets('lists the six times and counts down to Asr', (tester) async {
      await pump(tester, _desktop);

      for (final time in [
        '05:22',
        '06:49',
        '12:44',
        '04:08',
        '06:39',
        '07:57',
      ]) {
        expect(find.text(time), findsOneWidget, reason: time);
      }
      expect(find.text('العصر'), findsNWidgets(2));
      expect(find.text('04:08 م'), findsOneWidget);
      // 13:00 → 16:08.
      expect(find.text('03'), findsOneWidget);
      expect(find.text('08'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
    });

    testWidgets('the countdown ticks every second', (tester) async {
      await pump(tester, _desktop);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('07'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
    });

    testWidgets("after Isha it counts down to tomorrow's Fajr", (tester) async {
      now = cairo(10, 2, 21);
      await pump(tester, _desktop);

      expect(find.text('الفجر'), findsNWidgets(2));
      // Tomorrow's own time (05:23), not today's.
      expect(find.text('05:23 ص'), findsOneWidget);
      // 21:00 → 05:23.
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('loads the new day once midnight has passed', (tester) async {
      now = cairo(10, 2, 23, 59, 59);
      await pump(tester, _desktop);
      now = cairo(10, 3, 0, 0, 1);
      await tester.pump(const Duration(seconds: 1));

      verify(() => prayer.refreshIfStale()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('describes the next prayer and the qibla to screen readers', (
      tester,
    ) async {
      await pump(tester, _desktop);
      expect(
        find.bySemanticsLabel(RegExp('^العصر، 04:08 م، الصلاة القادمة')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^اتجاه القبلة 136.2°')),
        findsOneWidget,
      );
    });

    testWidgets('while loading, times show placeholders', (tester) async {
      when(
        () => prayer.state,
      ).thenReturn(const PrayerTimesState(status: PrayerTimesStatus.loading));
      await pump(tester, _desktop);

      // Six rows and the next prayer's time.
      expect(find.text('--:--'), findsNWidgets(7));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failure with nothing to show offers a retry', (
      tester,
    ) async {
      when(() => prayer.state).thenReturn(
        const PrayerTimesState(
          status: PrayerTimesStatus.failure,
          errorMessage: 'تعذّر الاتصال بالإنترنت',
        ),
      );
      await pump(tester, _desktop);

      expect(find.text('تعذّر تحميل المواقيت'), findsOneWidget);
      expect(find.text('تعذّر الاتصال بالإنترنت'), findsOneWidget);
      // The qibla is calculated on the device.
      expect(find.byType(QiblaDial), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      verify(() => prayer.retry()).called(1);
    });

    testWidgets('times from an old download say so', (tester) async {
      when(() => prayer.state).thenReturn(
        PrayerTimesState(
          status: PrayerTimesStatus.success,
          times: _withFetchedAt(cairoTimes(10, 2), DateTime.utc(2026, 9, 28)),
        ),
      );
      await pump(tester, _desktop);

      expect(
        find.textContaining('محفوظة على جهازك منذ 28 سبتمبر'),
        findsOneWidget,
      );
    });

    testWidgets('fresh times say nothing about the cache', (tester) async {
      when(() => prayer.state).thenReturn(
        PrayerTimesState(
          status: PrayerTimesStatus.success,
          times: _withFetchedAt(cairoTimes(10, 2), cairo(10, 2, 9)),
        ),
      );
      await pump(tester, _desktop);

      expect(find.textContaining('محفوظة على جهازك'), findsNothing);
    });

    testWidgets('a nearby city switches the location', (tester) async {
      await pump(tester, _desktop);

      expect(find.text('7 km'), findsOneWidget);
      await tester.tap(find.text('الجيزة'));
      verify(() => prayer.changeLocation(_giza)).called(1);
    });

    testWidgets("the country button lists the country's cities", (
      tester,
    ) async {
      await pump(tester, _desktop);

      await tester.tap(find.text('مدن مصر'));
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS cities=EG'), findsOneWidget);
    });

    testWidgets('"all cities" lists every city', (tester) async {
      await pump(tester, _desktop);

      await tester.tap(find.text('جميع المدن'));
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS cities=all'), findsOneWidget);
    });

    testWidgets('"use my location" locates the device', (tester) async {
      await pump(tester, _desktop);

      await tester.ensureVisible(find.text('استخدم موقعي'));
      await tester.tap(find.text('استخدم موقعي'));
      verify(() => device.locate()).called(1);
    });

    testWidgets('the located position becomes the location', (tester) async {
      const here = PrayerLocation(
        id: PrayerLocation.deviceId,
        name: 'قرب الجيزة',
        nameEn: 'Near Giza',
        country: 'مصر',
        countryCode: 'EG',
        latitude: 30.001,
        longitude: 31.2,
        timeZone: 'Africa/Cairo',
      );
      whenListen(
        device,
        Stream.fromIterable(const [
          DeviceLocationState(status: DeviceLocationStatus.locating),
          DeviceLocationState(
            status: DeviceLocationStatus.located,
            location: here,
          ),
        ]),
        initialState: const DeviceLocationState(),
      );
      await pump(tester, _desktop);
      await tester.pump();

      verify(() => prayer.changeLocation(here)).called(1);
      expect(find.text('تم تحديد موقعك: قرب الجيزة'), findsOneWidget);
    });

    testWidgets('a refusal says what to do instead', (tester) async {
      whenListen(
        device,
        Stream.fromIterable(const [
          DeviceLocationState(
            status: DeviceLocationStatus.failure,
            failure: LocationFailure(LocationProblem.denied),
          ),
        ]),
        initialState: const DeviceLocationState(),
      );
      await pump(tester, _desktop);
      await tester.pump();

      verifyNever(() => prayer.changeLocation(any()));
      expect(
        find.text('لم يُسمح بمعرفة موقعك؛ يمكنك اختيار مدينتك من القائمة.'),
        findsOneWidget,
      );
    });

    testWidgets('the live compass is not available yet', (tester) async {
      await pump(tester, _desktop);

      await tester.ensureVisible(find.text('ابدأ البوصلة الحية'));
      await tester.tap(find.text('ابدأ البوصلة الحية'));
      await tester.pump();
      expect(find.text('قريبًا إن شاء الله'), findsOneWidget);
    });

    testWidgets('tabs switch screens', (tester) async {
      await pump(tester, _desktop);

      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS '), findsOneWidget);
    });

    testWidgets('tabs, chips and buttons are at least 44 high', (tester) async {
      await pump(tester, _desktop);

      for (final label in [
        'الجدول الشهري',
        'الجيزة',
        'مدن مصر',
        'استخدم موقعي',
      ]) {
        final box = find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first;
        expect(
          tester.getSize(box).height,
          greaterThanOrEqualTo(44),
          reason: label,
        );
      }
    });
  });

  group('times tab, mobile', () {
    testWidgets('uses the phone layout without the design canvas', (
      tester,
    ) async {
      await pump(tester, _mobile);

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(TodayPanel),
          matching: find.byType(DesignBox),
        ),
        findsNothing,
      );
      expect(find.text('الصلاة القادمة'), findsOneWidget);
      expect(find.byType(QiblaDial), findsOneWidget);
    });

    for (final width in [360.0, 390.0]) {
      for (final scale in [1.15, 1.3]) {
        testWidgets('fits a ${scale}x system font at $width', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await pump(tester, Size(width, 4600));

          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('desktop fits a 1.3x system font', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester, _desktop);

    expect(tester.takeException(), isNull);
  });

  // Android builds the first frame at width 0.
  testWidgets('survives the zero-width first frame, then lays out', (
    tester,
  ) async {
    await pump(tester, const Size(0, 800));
    expect(tester.takeException(), isNull);

    await pump(tester, _mobile);
    expect(tester.takeException(), isNull);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
  });
}
