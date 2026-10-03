import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/data/datasources/prayer_local_data_source.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/prayer_preferences_usecases.dart';
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_alerts_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/pages/prayer_page.dart';
import 'package:manara/features/prayer/presentation/utils/alert_text.dart';
import 'package:manara/features/prayer/presentation/widgets/alerts/prayer_alert_scheduler.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fonts.dart';
import '../../helpers/prayer_fixtures.dart';

class MockGetAlerts extends Mock implements GetAlertSettings {}

class MockSaveAlerts extends Mock implements SaveAlertSettings {}

class MockNotifier extends Mock implements AlertNotifier {}

class MockPrayerTimesCubit extends MockCubit<PrayerTimesState>
    implements PrayerTimesCubit {}

class MockPrayerAlertsCubit extends MockCubit<PrayerAlertsState>
    implements PrayerAlertsCubit {}

class MockNearbyCitiesCubit extends MockCubit<NearbyCitiesState>
    implements NearbyCitiesCubit {}

const _fajrAt = AlertSettings(
  prayers: {Prayer.fajr: PrayerAlert(enabled: true)},
);

void main() {
  setUpAll(() {
    registerFallbackValue(const AlertSettings());
    registerFallbackValue(const NoParams());
  });

  // 2 Oct 2026 is a Friday. Cairo: Fajr 05:22, Dhuhr 12:44, Isha 19:57;
  // 3 Oct Fajr 05:23.
  final times = cairoTimes(10, 2);

  group('AlertEvent.next', () {
    test('nothing when no alert is on', () {
      expect(
        AlertEvent.next(times, const AlertSettings(), cairo(10, 2, 3)),
        isNull,
      );
    });

    test('at the prayer time', () {
      final event = AlertEvent.next(times, _fajrAt, cairo(10, 2, 3))!;
      expect(event.at, cairo(10, 2, 5, 22));
      expect(event.kind, AlertKind.prayer);
      expect(event.minutes, 0);
    });

    test('minutes before the prayer', () {
      const settings = AlertSettings(
        prayers: {Prayer.asr: PrayerAlert(enabled: true, minutesBefore: 10)},
      );
      final event = AlertEvent.next(times, settings, cairo(10, 2, 13))!;
      expect(event.at, cairo(10, 2, 15, 58));
      expect(event.prayer, Prayer.asr);
    });

    test("after Isha, tomorrow's own Fajr", () {
      final event = AlertEvent.next(times, _fajrAt, cairo(10, 2, 21))!;
      expect(event.at, cairo(10, 3, 5, 23));
    });

    test('the moment itself has passed: the next one', () {
      final event = AlertEvent.next(times, _fajrAt, cairo(10, 2, 5, 22))!;
      expect(event.at, cairo(10, 3, 5, 23));
    });

    test('suhoor is 40 minutes before Fajr', () {
      final event = AlertEvent.next(
        times,
        const AlertSettings(suhoor: true),
        cairo(10, 2, 3),
      )!;
      expect(event.at, cairo(10, 2, 4, 42));
      expect(event.kind, AlertKind.suhoor);
    });

    test('the Friday alert is an hour before Dhuhr, on Fridays only', () {
      const friday = AlertSettings(friday: true);
      final event = AlertEvent.next(times, friday, cairo(10, 2, 9))!;
      expect(event.at, cairo(10, 2, 11, 44));
      expect(event.kind, AlertKind.friday);
      // After Friday's alert, Saturday (tomorrow) has none.
      expect(AlertEvent.next(times, friday, cairo(10, 2, 12)), isNull);
    });

    test('the earliest of several', () {
      const settings = AlertSettings(
        suhoor: true,
        prayers: {Prayer.isha: PrayerAlert(enabled: true)},
      );
      final event = AlertEvent.next(times, settings, cairo(10, 2, 18))!;
      expect(event.prayer, Prayer.isha);
    });
  });

  group('alertText', () {
    AlertEvent event(AlertKind kind, Prayer prayer, int minutes) => AlertEvent(
      at: DateTime.utc(2026),
      kind: kind,
      prayer: prayer,
      minutes: minutes,
    );

    test('reads naturally with Arabic number agreement', () {
      expect(alertText(event(AlertKind.prayer, Prayer.fajr, 0)), (
        'حان وقت صلاة الفجر',
        'دخل الآن وقت الفجر.',
      ));
      expect(alertText(event(AlertKind.prayer, Prayer.dhuhr, 10)), (
        'اقترب وقت صلاة الظهر',
        'أذان الظهر بعد 10 دقائق.',
      ));
      expect(
        alertText(event(AlertKind.prayer, Prayer.asr, 15)).$2,
        'أذان العصر بعد 15 دقيقة.',
      );
      expect(alertText(event(AlertKind.suhoor, Prayer.fajr, 40)), (
        'تنبيه السحور',
        'أذان الفجر بعد 40 دقيقة.',
      ));
      expect(
        alertText(event(AlertKind.friday, Prayer.dhuhr, 60)).$1,
        'تنبيه الجمعة',
      );
    });
  });

  group('stored alert settings', () {
    test('round-trip, and unknown values fall back to off', () async {
      SharedPreferences.setMockInitialValues({});
      final local = PrayerLocalDataSourceImpl(
        await SharedPreferences.getInstance(),
      );
      expect(local.readAlerts(), const AlertSettings());

      const settings = AlertSettings(
        suhoor: true,
        prayers: {Prayer.maghrib: PrayerAlert(enabled: true, minutesBefore: 5)},
      );
      await local.writeAlerts(settings);
      expect(local.readAlerts(), settings);

      SharedPreferences.setMockInitialValues({
        'prayer.alerts':
            '{"prayers": {"fajr": {"enabled": true, "minutesBefore": 7}}}',
      });
      final odd = PrayerLocalDataSourceImpl(
        await SharedPreferences.getInstance(),
      ).readAlerts();
      expect(odd.alertOf(Prayer.fajr), const PrayerAlert(enabled: true));
    });
  });

  group('PrayerAlertsCubit', () {
    late MockGetAlerts get;
    late MockSaveAlerts save;
    late MockNotifier notifier;

    setUp(() {
      get = MockGetAlerts();
      save = MockSaveAlerts();
      notifier = MockNotifier();
      when(
        () => get(any()),
      ).thenAnswer((_) async => const Right(AlertSettings()));
      when(() => save(any())).thenAnswer((_) async => const Right(unit));
      when(() => notifier.permission).thenReturn('default');
      when(
        () => notifier.requestPermission(),
      ).thenAnswer((_) async => 'granted');
    });

    blocTest<PrayerAlertsCubit, PrayerAlertsState>(
      'loads the saved choices and the permission',
      build: () => PrayerAlertsCubit(get, save, notifier),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PrayerAlertsState(permission: 'default', loaded: true),
      ],
    );

    blocTest<PrayerAlertsCubit, PrayerAlertsState>(
      'a failed read leaves everything off',
      setUp: () => when(
        () => get(any()),
      ).thenAnswer((_) async => const Left(CacheFailure())),
      build: () => PrayerAlertsCubit(get, save, notifier),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.settings, const AlertSettings()),
    );

    blocTest<PrayerAlertsCubit, PrayerAlertsState>(
      'turning the first alert on saves it and asks the browser',
      build: () => PrayerAlertsCubit(get, save, notifier),
      act: (cubit) async {
        await cubit.load();
        await cubit.update(_fajrAt);
      },
      verify: (cubit) {
        verify(() => save(_fajrAt)).called(1);
        verify(() => notifier.requestPermission()).called(1);
        expect(cubit.state.canNotify, isTrue);
      },
    );

    blocTest<PrayerAlertsCubit, PrayerAlertsState>(
      'does not ask where notifications are not supported',
      setUp: () => when(() => notifier.permission).thenReturn('unsupported'),
      build: () => PrayerAlertsCubit(get, save, notifier),
      act: (cubit) async {
        await cubit.load();
        await cubit.update(_fajrAt);
      },
      verify: (_) => verifyNever(() => notifier.requestPermission()),
    );
  });

  group('PrayerAlertScheduler', () {
    late MockPrayerTimesCubit prayer;
    late MockPrayerAlertsCubit alerts;
    late MockNotifier notifier;
    late DateTime now;

    setUp(() {
      prayer = MockPrayerTimesCubit();
      alerts = MockPrayerAlertsCubit();
      notifier = MockNotifier();
      now = cairo(10, 2, 5, 21, 58);
      when(() => prayer.state).thenReturn(
        PrayerTimesState(status: PrayerTimesStatus.success, times: times),
      );
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<PrayerTimesCubit>.value(value: prayer),
              BlocProvider<PrayerAlertsCubit>.value(value: alerts),
            ],
            child: PrayerAlertScheduler(
              notifier: notifier,
              clock: () => now,
              child: const Scaffold(body: Text('PAGE')),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows an in-app alert at Fajr', (tester) async {
      when(
        () => alerts.state,
      ).thenReturn(const PrayerAlertsState(settings: _fajrAt, loaded: true));
      await pump(tester);

      expect(find.textContaining('حان وقت صلاة الفجر'), findsNothing);
      now = cairo(10, 2, 5, 22);
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('حان وقت صلاة الفجر'), findsOneWidget);
      verifyNever(() => notifier.show(any(), any()));
    });

    testWidgets('uses a system notification when allowed', (tester) async {
      when(() => alerts.state).thenReturn(
        const PrayerAlertsState(
          settings: _fajrAt,
          permission: 'granted',
          loaded: true,
        ),
      );
      await pump(tester);
      now = cairo(10, 2, 5, 22);
      await tester.pump(const Duration(seconds: 2));

      verify(
        () => notifier.show('حان وقت صلاة الفجر', 'دخل الآن وقت الفجر.'),
      ).called(1);
    });

    testWidgets('does nothing when every alert is off', (tester) async {
      when(
        () => alerts.state,
      ).thenReturn(const PrayerAlertsState(loaded: true));
      await pump(tester);
      await tester.pump(const Duration(minutes: 5));

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('alerts tab', () {
    late MockPrayerTimesCubit prayer;
    late MockPrayerAlertsCubit alerts;
    late MockNearbyCitiesCubit nearby;

    setUp(() {
      prayer = MockPrayerTimesCubit();
      alerts = MockPrayerAlertsCubit();
      nearby = MockNearbyCitiesCubit();
      when(() => prayer.state).thenReturn(
        PrayerTimesState(status: PrayerTimesStatus.success, times: times),
      );
      when(() => nearby.state).thenReturn(const NearbyCitiesState());
      when(
        () => alerts.state,
      ).thenReturn(const PrayerAlertsState(loaded: true));
      when(() => alerts.update(any())).thenAnswer((_) async {});
    });

    Future<void> pump(WidgetTester tester, Size size) async {
      await loadAppFonts(tester);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<PrayerTimesCubit>.value(value: prayer),
              BlocProvider<PrayerAlertsCubit>.value(value: alerts),
              BlocProvider<NearbyCitiesCubit>.value(value: nearby),
            ],
            child: PrayerView(
              tab: PrayerTab.alerts,
              clock: () => cairo(10, 2, 13),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('lists the five prayers and the extra alerts', (tester) async {
      await pump(tester, const Size(1440, 2800));

      for (final text in [
        'تنبيهات الصلاة',
        'الصلوات الخمس',
        'تنبيهات إضافية',
        'تنبيه السحور',
        'تنبيه الجمعة',
        'قبل أذان الفجر بـ 40 دقيقة',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // Five prayers + suhoor + Friday.
      expect(find.byType(Switch), findsNWidgets(7));
      // Sunrise is not a prayer: no alert for it.
      expect(find.text('الشروق'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a switch turns an alert on', (tester) async {
      await pump(tester, const Size(1440, 2800));

      await tester.tap(find.byType(Switch).first);
      verify(
        () => alerts.update(
          const AlertSettings(
            prayers: {Prayer.fajr: PrayerAlert(enabled: true)},
          ),
        ),
      ).called(1);
    });

    testWidgets('tone and voice are not available yet', (tester) async {
      await pump(tester, const Size(1440, 2800));
      expect(find.bySemanticsLabel('صوت المؤذن: قريبًا'), findsNWidgets(5));
    });

    testWidgets('mobile fits a 1.3x system font', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, const Size(360, 6000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives the zero-width first frame', (tester) async {
      await pump(tester, const Size(0, 800));
      expect(tester.takeException(), isNull);
    });
  });
}
