import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart';
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_month_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/pages/prayer_page.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_export.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fonts.dart';
import '../../../helpers/prayer_fixtures.dart';

class MockGetPrayerMonth extends Mock implements GetPrayerMonth {}

class MockPrayerTimesCubit extends MockCubit<PrayerTimesState>
    implements PrayerTimesCubit {}

class MockNearbyCitiesCubit extends MockCubit<NearbyCitiesState>
    implements NearbyCitiesCubit {}

class MockPrayerMonthCubit extends MockCubit<PrayerMonthState>
    implements PrayerMonthCubit {}

const _settings = PrayerSettings();

void main() {
  setUpAll(() {
    registerFallbackValue(
      const PrayerMonthParams(
        location: PrayerLocation.cairo,
        settings: _settings,
        year: 2026,
        month: 10,
      ),
    );
    registerFallbackValue(PrayerLocation.cairo);
    registerFallbackValue(_settings);
  });

  group('PrayerMonthCubit', () {
    late MockGetPrayerMonth getMonth;

    setUp(() {
      getMonth = MockGetPrayerMonth();
      when(() => getMonth(any())).thenAnswer((inv) async {
        final p = inv.positionalArguments.first as PrayerMonthParams;
        return p.month == 10 ? Right(cairoOctober()) : Right(cairoDecember());
      });
    });

    Future<void> showOctober(PrayerMonthCubit cubit) => cubit.show(
      year: 2026,
      month: 10,
      location: PrayerLocation.cairo,
      settings: _settings,
    );

    blocTest<PrayerMonthCubit, PrayerMonthState>(
      'loads a month',
      build: () => PrayerMonthCubit(getMonth),
      act: showOctober,
      expect: () => [
        const PrayerMonthState(
          year: 2026,
          month: 10,
          status: PrayerMonthStatus.loading,
        ),
        PrayerMonthState(
          year: 2026,
          month: 10,
          status: PrayerMonthStatus.success,
          data: cairoOctober(),
        ),
      ],
    );

    blocTest<PrayerMonthCubit, PrayerMonthState>(
      'steps across the year end',
      build: () => PrayerMonthCubit(getMonth),
      act: (cubit) async {
        await cubit.show(
          year: 2026,
          month: 12,
          location: PrayerLocation.cairo,
          settings: _settings,
        );
        await cubit.step(1);
      },
      verify: (cubit) {
        expect((cubit.state.year, cubit.state.month), (2027, 1));
        final asked =
            verify(() => getMonth(captureAny())).captured.last
                as PrayerMonthParams;
        expect((asked.year, asked.month), (2027, 1));
      },
    );

    blocTest<PrayerMonthCubit, PrayerMonthState>(
      'showing the same month again does nothing',
      build: () => PrayerMonthCubit(getMonth),
      act: (cubit) async {
        await showOctober(cubit);
        await showOctober(cubit);
      },
      verify: (_) => verify(() => getMonth(any())).called(1),
    );

    blocTest<PrayerMonthCubit, PrayerMonthState>(
      'a new city reloads the same month',
      build: () => PrayerMonthCubit(getMonth),
      act: (cubit) async {
        await showOctober(cubit);
        await cubit.show(
          year: 2026,
          month: 10,
          location: PrayerLocation.cairo,
          settings: const PrayerSettings(school: AsrSchool.hanafi),
        );
      },
      verify: (_) => verify(() => getMonth(any())).called(2),
    );

    blocTest<PrayerMonthCubit, PrayerMonthState>(
      'a failure is shown and can be retried',
      setUp: () => when(
        () => getMonth(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline'))),
      build: () => PrayerMonthCubit(getMonth),
      act: (cubit) async {
        await showOctober(cubit);
        await cubit.retry();
      },
      expect: () => [
        const PrayerMonthState(
          year: 2026,
          month: 10,
          status: PrayerMonthStatus.loading,
        ),
        const PrayerMonthState(
          year: 2026,
          month: 10,
          status: PrayerMonthStatus.failure,
          errorMessage: 'offline',
        ),
        const PrayerMonthState(
          year: 2026,
          month: 10,
          status: PrayerMonthStatus.loading,
        ),
        const PrayerMonthState(
          year: 2026,
          month: 10,
          status: PrayerMonthStatus.failure,
          errorMessage: 'offline',
        ),
      ],
    );

    blocTest<PrayerMonthCubit, PrayerMonthState>(
      'a slow month the user moved past is dropped',
      build: () => PrayerMonthCubit(getMonth),
      act: (cubit) async {
        final slow = Completer<Either<Failure, PrayerMonth>>();
        when(() => getMonth(any())).thenAnswer((_) => slow.future);
        final first = showOctober(cubit);
        when(
          () => getMonth(any()),
        ).thenAnswer((_) async => Right(cairoDecember()));
        await cubit.show(
          year: 2026,
          month: 12,
          location: PrayerLocation.cairo,
          settings: _settings,
        );
        slow.complete(Right(cairoOctober()));
        await first;
      },
      verify: (cubit) {
        expect(cubit.state.month, 12);
        expect(cubit.state.data!.month, 12);
      },
    );
  });

  group('PrayerExport.ics', () {
    final ics = PrayerExport.ics(
      month: cairoOctober(),
      location: PrayerLocation.cairo,
      now: DateTime.utc(2026, 10, 2, 9),
    );
    final lines = ics.split('\r\n');

    test('is a calendar with five prayers for each of the 31 days', () {
      expect(lines.first, 'BEGIN:VCALENDAR');
      expect(lines.where((l) => l == 'BEGIN:VEVENT'), hasLength(31 * 5));
      expect(ics, endsWith('END:VCALENDAR\r\n'));
      expect(ics, isNot(contains('الشروق')));
    });

    test('writes each prayer at its moment in UTC', () {
      // 2 Oct Fajr 05:22 (UTC+3); 30 Oct Fajr 04:39 (UTC+2).
      expect(lines, contains('DTSTART:20261002T022200Z'));
      expect(lines, contains('DTSTART:20261030T023900Z'));
      expect(lines, contains('UID:20261002-fajr-360630@manara'));
    });

    test('keeps every line within 75 octets', () {
      for (final line in lines) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75), reason: line);
      }
    });

    test('escapes commas in text', () {
      final named = PrayerExport.ics(
        month: cairoOctober(),
        location: const PrayerLocation(
          id: 1,
          name: 'مدينة, اختبار',
          nameEn: 'Test',
          country: 'x',
          countryCode: 'XX',
          latitude: 0,
          longitude: 0,
          timeZone: 'UTC',
        ),
        now: DateTime.utc(2026),
      );
      expect(named, contains(r'مدينة\, اختبار'));
    });
  });

  group('PrayerExport.printableHtml', () {
    test('is a right-to-left page with every day and the note', () {
      final html = PrayerExport.printableHtml(
        month: cairoOctober(),
        location: PrayerLocation.cairo,
        methodLabel: 'الهيئة المصرية العامة للمساحة',
      );
      expect(html, contains('dir="rtl"'));
      expect('<tr>'.allMatches(html), hasLength(32));
      expect(html, contains('05:22 ص'));
      expect(html, contains('تُحسب مواقيت الصلاة فلكيًا'));
    });

    test('escapes names', () {
      final html = PrayerExport.printableHtml(
        month: cairoOctober(),
        location: PrayerLocation.cairo,
        methodLabel: '<b>',
      );
      expect(html, contains('&lt;b&gt;'));
    });
  });

  group('monthly tab', () {
    late MockPrayerTimesCubit prayer;
    late MockPrayerMonthCubit month;
    late MockNearbyCitiesCubit nearby;

    setUp(() {
      prayer = MockPrayerTimesCubit();
      month = MockPrayerMonthCubit();
      nearby = MockNearbyCitiesCubit();
      when(() => prayer.state).thenReturn(
        PrayerTimesState(
          status: PrayerTimesStatus.success,
          times: cairoTimes(10, 2),
        ),
      );
      when(() => nearby.state).thenReturn(const NearbyCitiesState());
      when(() => month.state).thenReturn(
        PrayerMonthState(
          year: 2026,
          month: 10,
          status: PrayerMonthStatus.success,
          data: cairoOctober(),
        ),
      );
      when(
        () => month.show(
          year: any(named: 'year'),
          month: any(named: 'month'),
          location: any(named: 'location'),
          settings: any(named: 'settings'),
        ),
      ).thenAnswer((_) async {});
      when(() => month.step(any())).thenAnswer((_) async {});
      when(() => month.retry()).thenAnswer((_) async {});
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
              BlocProvider<NearbyCitiesCubit>.value(value: nearby),
              BlocProvider<PrayerMonthCubit>.value(value: month),
            ],
            child: PrayerView(
              tab: PrayerTab.monthly,
              clock: () => cairo(10, 2, 13),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('asks for the location month on open', (tester) async {
      when(() => month.state).thenReturn(const PrayerMonthState());
      await pump(tester, const Size(1440, 2800));

      verify(
        () => month.show(
          year: 2026,
          month: 10,
          location: PrayerLocation.cairo,
          settings: _settings,
        ),
      ).called(1);
    });

    testWidgets('desktop: the table has every day of October', (tester) async {
      await pump(tester, const Size(1440, 2800));

      expect(find.byType(Table), findsOneWidget);
      expect(
        find.text('جدول مواقيت الصلاة الشهري لمدينة القاهرة'),
        findsOneWidget,
      );
      expect(find.text('أكتوبر 2026'), findsOneWidget);
      expect(find.text('21/4'), findsOneWidget);
      // 30 Oct is in UTC+2: Fajr 04:39.
      expect(find.text('04:39 ص'), findsOneWidget);
      expect(find.bySemanticsLabel('2 الجمعة، اليوم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('month arrows step the month', (tester) async {
      await pump(tester, const Size(1440, 2800));

      await tester.tap(find.byTooltip('الشهر التالي'));
      verify(() => month.step(1)).called(1);
      await tester.tap(find.byTooltip('الشهر السابق'));
      verify(() => month.step(-1)).called(1);
    });

    testWidgets('outside the browser, export and print are not ready', (
      tester,
    ) async {
      await pump(tester, const Size(1440, 2800));

      await tester.tap(find.text('تصدير iCal'));
      await tester.pump();
      expect(find.text('قريبًا إن شاء الله'), findsOneWidget);
    });

    testWidgets('a failure offers a retry', (tester) async {
      when(() => month.state).thenReturn(
        const PrayerMonthState(
          year: 2026,
          month: 10,
          status: PrayerMonthStatus.failure,
          errorMessage: 'offline',
        ),
      );
      await pump(tester, const Size(1440, 2800));

      expect(find.text('تعذّر تحميل الجدول'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      verify(() => month.retry()).called(1);
    });

    testWidgets('while loading, a spinner shows', (tester) async {
      when(() => month.state).thenReturn(
        const PrayerMonthState(
          year: 2026,
          month: 11,
          status: PrayerMonthStatus.loading,
        ),
      );
      await pump(tester, const Size(1440, 2800));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('نوفمبر 2026'), findsOneWidget);
    });

    testWidgets('mobile: one card per day, today marked', (tester) async {
      await pump(tester, const Size(390, 6000));

      expect(find.byType(Table), findsNothing);
      expect(find.text('2 الجمعة (اليوم)'), findsOneWidget);
      expect(find.text('31 السبت'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final width in [360.0, 390.0]) {
      testWidgets('mobile fits a 1.3x system font at $width', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester, Size(width, 8000));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives the zero-width first frame', (tester) async {
      await pump(tester, const Size(0, 800));
      expect(tester.takeException(), isNull);
    });
  });
}
