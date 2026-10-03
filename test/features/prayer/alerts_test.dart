import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/platform/local_notifications.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/prayer/data/datasources/prayer_local_data_source.dart';
import 'package:manara/features/prayer/domain/entities/prayer_alerts.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';
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

class MockUpcomingDays extends Mock implements GetUpcomingPrayerDays {}

class MockLocalNotifications extends Mock implements LocalNotifications {}

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
    registerFallbackValue(
      UpcomingDaysParams(
        now: DateTime.utc(2026),
        location: PrayerLocation.cairo,
        settings: const PrayerSettings(),
        count: 1,
      ),
    );
    registerFallbackValue(<ScheduledAlert>[]);
    registerFallbackValue(PrayerLocation.cairo);
    registerFallbackValue(const PrayerSettings());
    registerFallbackValue(DateTime.utc(2026));
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

  group('AlertEvent.upcoming', () {
    final days = cairoOctober().allDays.skip(5).take(3); // 2–4 Oct.

    test('every alert on the days, soonest first', () {
      const settings = AlertSettings(
        suhoor: true,
        prayers: {Prayer.fajr: PrayerAlert(enabled: true)},
      );
      final events = AlertEvent.upcoming(days, settings, cairo(10, 2, 3));
      expect(events.map((e) => (e.kind, e.at)), [
        (AlertKind.suhoor, cairo(10, 2, 4, 42)),
        (AlertKind.prayer, cairo(10, 2, 5, 22)),
        (AlertKind.suhoor, cairo(10, 3, 4, 43)),
        (AlertKind.prayer, cairo(10, 3, 5, 23)),
        (AlertKind.suhoor, cairo(10, 4, 4, 44)),
        (AlertKind.prayer, cairo(10, 4, 5, 24)),
      ]);
    });

    test('only after the moment, and at most the limit', () {
      final events = AlertEvent.upcoming(
        days,
        _fajrAt,
        cairo(10, 2, 6),
        limit: 1,
      );
      expect(events.single.at, cairo(10, 3, 5, 23));
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
    late MockUpcomingDays upcoming;

    setUp(() {
      get = MockGetAlerts();
      save = MockSaveAlerts();
      notifier = MockNotifier();
      upcoming = MockUpcomingDays();
      when(
        () => get(any()),
      ).thenAnswer((_) async => const Right(AlertSettings()));
      when(() => save(any())).thenAnswer((_) async => const Right(unit));
      when(() => notifier.checkPermission()).thenAnswer((_) async => 'default');
      when(() => notifier.exactAllowed()).thenAnswer((_) async => true);
      when(() => notifier.schedulesAhead).thenReturn(false);
      when(() => notifier.schedule(any())).thenAnswer((_) async {});
      when(
        () => notifier.requestPermission(),
      ).thenAnswer((_) async => 'granted');
      when(() => upcoming(any())).thenAnswer(
        (_) async => Right(cairoOctober().allDays.skip(5).take(10).toList()),
      );
    });

    PrayerAlertsCubit build() => PrayerAlertsCubit(
      get,
      save,
      notifier,
      upcoming,
      clock: () => cairo(10, 2, 3),
    );

    blocTest<PrayerAlertsCubit, PrayerAlertsState>(
      'loads the saved choices and the permission',
      build: build,
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
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.settings, const AlertSettings()),
    );

    blocTest<PrayerAlertsCubit, PrayerAlertsState>(
      'turning the first alert on saves it and asks the browser',
      build: build,
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
      setUp: () => when(
        () => notifier.checkPermission(),
      ).thenAnswer((_) async => 'unsupported'),
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.update(_fajrAt);
      },
      verify: (_) => verifyNever(() => notifier.requestPermission()),
    );

    group('on a device', () {
      setUp(() {
        when(() => notifier.schedulesAhead).thenReturn(true);
        when(
          () => notifier.checkPermission(),
        ).thenAnswer((_) async => 'granted');
        when(() => get(any())).thenAnswer((_) async => const Right(_fajrAt));
      });

      Future<PrayerAlertsCubit> loaded() async {
        final cubit = build();
        await cubit.load();
        return cubit;
      }

      test('loads whether alerts are scheduled and exact', () async {
        when(() => notifier.exactAllowed()).thenAnswer((_) async => false);
        final cubit = await loaded();
        expect(cubit.state.schedulesAhead, isTrue);
        expect(cubit.state.exact, isFalse);
        expect(cubit.state.canNotify, isTrue);
      });

      test('schedules the coming days with their text', () async {
        final cubit = await loaded();
        await cubit.syncSystem(PrayerLocation.cairo, const PrayerSettings());

        final params =
            verify(() => upcoming(captureAny())).captured.single
                as UpcomingDaysParams;
        expect(params.count, PrayerAlertsCubit.scheduleDays);
        expect(params.location, PrayerLocation.cairo);
        final alerts =
            verify(() => notifier.schedule(captureAny())).captured.single
                as List<ScheduledAlert>;
        // Fajr on each of the ten days, 2–11 Oct.
        expect(alerts, hasLength(10));
        expect(
          alerts.first,
          ScheduledAlert(
            at: cairo(10, 2, 5, 22),
            title: 'حان وقت صلاة الفجر',
            body: 'دخل الآن وقت الفجر.',
          ),
        );
        expect(
          alerts.last.at,
          cairoOctober().allDays
              .firstWhere((d) => d.date == DateTime.utc(2026, 10, 11))
              .timeOf(Prayer.fajr)
              .instant,
        );
      });

      test('keeps within what iOS holds', () async {
        when(() => get(any())).thenAnswer(
          (_) async => Right(
            AlertSettings(
              suhoor: true,
              friday: true,
              prayers: {
                for (final p in Prayer.values.where((p) => p.isPrayer))
                  p: const PrayerAlert(enabled: true),
              },
            ),
          ),
        );
        final cubit = await loaded();
        await cubit.syncSystem(PrayerLocation.cairo, const PrayerSettings());
        final alerts =
            verify(() => notifier.schedule(captureAny())).captured.single
                as List<ScheduledAlert>;
        expect(alerts, hasLength(PrayerAlertsCubit.maxScheduled));
      });

      test('clears the schedule without permission', () async {
        when(
          () => notifier.checkPermission(),
        ).thenAnswer((_) async => 'default');
        final cubit = await loaded();
        await cubit.syncSystem(PrayerLocation.cairo, const PrayerSettings());
        verify(() => notifier.schedule(const [])).called(1);
        verifyNever(() => upcoming(any()));
      });

      test('keeps the schedule when the times are unavailable', () async {
        when(
          () => upcoming(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        final cubit = await loaded();
        await cubit.syncSystem(PrayerLocation.cairo, const PrayerSettings());
        verifyNever(() => notifier.schedule(any()));
      });

      test('a newer sync wins over an older one still loading', () async {
        final cubit = await loaded();
        await Future.wait([
          cubit.syncSystem(PrayerLocation.cairo, const PrayerSettings()),
          cubit.syncSystem(PrayerLocation.cairo, const PrayerSettings()),
        ]);
        verify(() => notifier.schedule(any())).called(1);
      });

      test('reads a permission granted in the settings', () async {
        when(
          () => notifier.checkPermission(),
        ).thenAnswer((_) async => 'default');
        when(() => notifier.exactAllowed()).thenAnswer((_) async => false);
        final cubit = await loaded();
        when(
          () => notifier.checkPermission(),
        ).thenAnswer((_) async => 'granted');
        when(() => notifier.exactAllowed()).thenAnswer((_) async => true);
        await cubit.refreshPermission();
        expect(cubit.state.canNotify, isTrue);
        expect(cubit.state.exact, isTrue);
      });

      test('asks for exact alarms', () async {
        when(() => notifier.exactAllowed()).thenAnswer((_) async => false);
        when(() => notifier.requestExact()).thenAnswer((_) async => true);
        final cubit = await loaded();
        await cubit.requestExact();
        expect(cubit.state.exact, isTrue);
      });

      test('does nothing where alerts are not scheduled ahead', () async {
        when(() => notifier.schedulesAhead).thenReturn(false);
        final cubit = await loaded();
        await cubit.syncSystem(PrayerLocation.cairo, const PrayerSettings());
        verifyNever(() => notifier.schedule(any()));
      });
    });
  });

  group('DeviceAlertNotifier', () {
    late MockLocalNotifications local;
    late DeviceAlertNotifier notifier;

    setUp(() {
      local = MockLocalNotifications();
      notifier = DeviceAlertNotifier(local);
      when(() => local.enabled()).thenAnswer((_) async => false);
      when(() => local.requestPermission()).thenAnswer((_) async => false);
      when(() => local.canScheduleExact()).thenAnswer((_) async => true);
      when(() => local.cancelAll()).thenAnswer((_) async {});
      when(
        () => local.schedule(
          id: any(named: 'id'),
          at: any(named: 'at'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          exact: any(named: 'exact'),
        ),
      ).thenAnswer((_) async {});
    });

    ScheduledAlert alert(int minute) => ScheduledAlert(
      at: DateTime.utc(2026, 10, 2, 3, minute),
      title: 'T$minute',
      body: 'B$minute',
    );

    void scheduled(int minute, {int id = 0, bool exact = true}) =>
        local.schedule(
          id: id,
          at: DateTime.utc(2026, 10, 2, 3, minute),
          title: 'T$minute',
          body: 'B$minute',
          exact: exact,
        );

    test('may ask until refused, then reads as denied', () async {
      expect(await notifier.checkPermission(), 'default');
      expect(await notifier.requestPermission(), 'denied');
      expect(await notifier.checkPermission(), 'denied');
      when(() => local.enabled()).thenAnswer((_) async => true);
      expect(await notifier.checkPermission(), 'granted');
    });

    test('replaces the schedule, exact when allowed', () async {
      when(() => local.canScheduleExact()).thenAnswer((_) async => false);
      await notifier.schedule([alert(1), alert(2)]);
      verifyInOrder([
        () => local.cancelAll(),
        () => scheduled(1, exact: false),
        () => scheduled(2, id: 1, exact: false),
      ]);
    });

    test('an empty list only clears', () async {
      await notifier.schedule(const []);
      verify(() => local.cancelAll()).called(1);
      verifyNever(() => local.canScheduleExact());
    });

    test('schedules one list after the other', () async {
      await Future.wait([
        notifier.schedule([alert(1)]),
        notifier.schedule([alert(2)]),
      ]);
      verifyInOrder([
        () => local.cancelAll(),
        () => scheduled(1),
        () => local.cancelAll(),
        () => scheduled(2),
      ]);
    });

    test('a failing plugin falls back to in-app alerts', () async {
      when(() => local.enabled()).thenThrow(Exception('no plugin'));
      when(() => local.canScheduleExact()).thenThrow(Exception('no plugin'));
      when(() => local.cancelAll()).thenThrow(Exception('no plugin'));
      expect(await notifier.checkPermission(), 'unsupported');
      expect(await notifier.exactAllowed(), isTrue);
      await expectLater(notifier.schedule([alert(1)]), completes);
    });
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
      when(() => notifier.schedulesAhead).thenReturn(false);
      when(() => alerts.syncSystem(any(), any())).thenAnswer((_) async {});
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

    testWidgets(
      'on a device the system shows them; only the schedule is kept',
      (tester) async {
        when(() => notifier.schedulesAhead).thenReturn(true);
        when(() => alerts.state).thenReturn(
          const PrayerAlertsState(
            settings: _fajrAt,
            permission: 'granted',
            schedulesAhead: true,
            loaded: true,
          ),
        );
        await pump(tester);
        verify(
          () => alerts.syncSystem(PrayerLocation.cairo, const PrayerSettings()),
        ).called(1);

        now = cairo(10, 2, 5, 22);
        await tester.pump(const Duration(seconds: 2));
        expect(find.textContaining('حان وقت صلاة الفجر'), findsNothing);
        verifyNever(() => notifier.show(any(), any()));
      },
    );

    testWidgets('on a device without permission, alerts show in the app', (
      tester,
    ) async {
      when(() => notifier.schedulesAhead).thenReturn(true);
      when(() => alerts.state).thenReturn(
        const PrayerAlertsState(
          settings: _fajrAt,
          permission: 'denied',
          schedulesAhead: true,
          loaded: true,
        ),
      );
      await pump(tester);
      now = cairo(10, 2, 5, 22);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('حان وقت صلاة الفجر'), findsOneWidget);
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

    testWidgets('on a device: asks for notifications', (tester) async {
      when(() => alerts.state).thenReturn(
        const PrayerAlertsState(
          settings: _fajrAt,
          permission: 'default',
          schedulesAhead: true,
          loaded: true,
        ),
      );
      when(() => alerts.requestPermission()).thenAnswer((_) async {});
      await pump(tester, const Size(390, 3000));

      expect(
        find.text('تنبيهات المواقيت على جهازك، وتصلك حتى والتطبيق مغلق.'),
        findsOneWidget,
      );
      expect(
        find.text('اسمح للتطبيق بالإشعارات لتصلك التنبيهات والتطبيق مغلق.'),
        findsOneWidget,
      );
      await tester.tap(find.text('السماح'));
      verify(() => alerts.requestPermission()).called(1);
    });

    testWidgets('on a device: asks for exact alarms', (tester) async {
      when(() => alerts.state).thenReturn(
        const PrayerAlertsState(
          settings: _fajrAt,
          permission: 'granted',
          exact: false,
          schedulesAhead: true,
          loaded: true,
        ),
      );
      when(() => alerts.requestExact()).thenAnswer((_) async {});
      await pump(tester, const Size(390, 3000));

      expect(find.textContaining('«المنبّهات والتذكيرات»'), findsOneWidget);
      final allow = find.ancestor(
        of: find.text('السماح'),
        matching: find.byType(TextButton),
      );
      expect(tester.getSize(allow).height, greaterThanOrEqualTo(44));
      await tester.tap(allow);
      verify(() => alerts.requestExact()).called(1);
    });

    testWidgets('on a device with everything allowed: no note', (tester) async {
      when(() => alerts.state).thenReturn(
        const PrayerAlertsState(
          settings: _fajrAt,
          permission: 'granted',
          schedulesAhead: true,
          loaded: true,
        ),
      );
      await pump(tester, const Size(390, 3000));
      expect(find.text('السماح'), findsNothing);
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

    for (final scale in [1.15, 1.3]) {
      testWidgets('the exact-alarm note fits a ${scale}x font at 360', (
        tester,
      ) async {
        when(() => alerts.state).thenReturn(
          const PrayerAlertsState(
            settings: _fajrAt,
            permission: 'granted',
            exact: false,
            schedulesAhead: true,
            loaded: true,
          ),
        );
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester, const Size(360, 6000));
        expect(find.textContaining('«المنبّهات والتذكيرات»'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives the zero-width first frame', (tester) async {
      await pump(tester, const Size(0, 800));
      expect(tester.takeException(), isNull);
    });
  });
}
