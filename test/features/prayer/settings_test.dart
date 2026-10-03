import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/prayer_settings.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/domain/repositories/city_repository.dart';
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart';
import 'package:manara/features/prayer/presentation/cubit/city_search_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/pages/prayer_page.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_form.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fonts.dart';
import '../../helpers/prayer_fixtures.dart';

class MockCityRepository extends Mock implements CityRepository {}

class MockPrayerTimesCubit extends MockCubit<PrayerTimesState>
    implements PrayerTimesCubit {}

class MockCitySearchCubit extends MockCubit<CitySearchState>
    implements CitySearchCubit {}

class MockNearbyCitiesCubit extends MockCubit<NearbyCitiesState>
    implements NearbyCitiesCubit {}

/// From assets/data/cities.json.
const _alexandria = PrayerLocation(
  id: 361058,
  name: 'الإسكندرية',
  nameEn: 'Alexandria',
  country: 'مصر',
  countryCode: 'EG',
  latitude: 31.20176,
  longitude: 29.91582,
  timeZone: 'Africa/Cairo',
);

void main() {
  setUpAll(() {
    registerFallbackValue(PrayerLocation.cairo);
    registerFallbackValue(const PrayerSettings());
  });

  group('CitySearchCubit', () {
    late MockCityRepository repository;

    setUp(() {
      repository = MockCityRepository();
      when(() => repository.getCities()).thenAnswer(
        (_) async => const Right([PrayerLocation.cairo, _alexandria]),
      );
    });

    CitySearchCubit build() => CitySearchCubit(SearchCities(repository));

    blocTest<CitySearchCubit, CitySearchState>(
      'searching lists matches',
      build: build,
      act: (cubit) => cubit.search('اسكندر'),
      expect: () => [
        const CitySearchState(query: 'اسكندر', results: [_alexandria]),
      ],
    );

    blocTest<CitySearchCubit, CitySearchState>(
      'an empty query closes the list',
      build: build,
      act: (cubit) => cubit.search('  '),
      expect: () => [const CitySearchState(query: '  ')],
      verify: (cubit) => expect(cubit.state.isOpen, isFalse),
    );

    blocTest<CitySearchCubit, CitySearchState>(
      'browsing a country lists all of its cities',
      build: build,
      act: (cubit) => cubit.browse(countryCode: 'EG'),
      verify: (cubit) {
        expect(cubit.state.isOpen, isTrue);
        expect(cubit.state.results, [PrayerLocation.cairo, _alexandria]);
      },
    );

    blocTest<CitySearchCubit, CitySearchState>(
      'clear closes the list',
      build: build,
      act: (cubit) async {
        await cubit.search('cai');
        cubit.clear();
      },
      skip: 1,
      expect: () => [const CitySearchState()],
    );
  });

  group('settings tab', () {
    late MockPrayerTimesCubit prayer;
    late MockCitySearchCubit search;
    late MockNearbyCitiesCubit nearby;

    setUp(() {
      prayer = MockPrayerTimesCubit();
      search = MockCitySearchCubit();
      nearby = MockNearbyCitiesCubit();
      when(() => prayer.state).thenReturn(
        PrayerTimesState(
          status: PrayerTimesStatus.success,
          times: cairoTimes(10, 2),
        ),
      );
      when(() => prayer.changeLocation(any())).thenAnswer((_) async {});
      when(() => prayer.changeSettings(any())).thenAnswer((_) async {});
      when(() => search.state).thenReturn(const CitySearchState());
      when(() => search.search(any())).thenAnswer((_) async {});
      when(() => nearby.state).thenReturn(const NearbyCitiesState());
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
              BlocProvider<CitySearchCubit>.value(value: search),
              BlocProvider<NearbyCitiesCubit>.value(value: nearby),
            ],
            child: PrayerView(
              tab: PrayerTab.settings,
              clock: () => cairo(10, 2, 13),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the city, the calculation and the adjustments', (
      tester,
    ) async {
      await pump(tester, const Size(1440, 2800));

      for (final text in [
        'إعدادات حساب المواقيت',
        'الموقع',
        'القاهرة، مصر',
        'المنطقة الزمنية: Africa/Cairo',
        'الحساب',
        'الضبط الدقيق',
        'استعادة الإعدادات الافتراضية',
        'بيانات المدن من GeoNames (CC BY 4.0).',
        'التاريخ الهجري اليوم: 21 ربيع الثاني 1448 هـ',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(
        find.bySemanticsLabel('طريقة الحساب: الهيئة المصرية العامة للمساحة'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing searches the city list', (tester) async {
      await pump(tester, const Size(1440, 2800));

      await tester.enterText(find.byType(TextField), 'اسك');
      verify(() => search.search('اسك')).called(1);
    });

    testWidgets('picking a result switches to it', (tester) async {
      when(
        () => search.state,
      ).thenReturn(const CitySearchState(query: 'اسك', results: [_alexandria]));
      when(() => search.clear()).thenReturn(null);
      await pump(tester, const Size(1440, 2800));

      await tester.tap(find.text('الإسكندرية'));
      await tester.pump();

      verify(() => prayer.changeLocation(_alexandria)).called(1);
      verify(() => search.clear()).called(1);
      expect(find.text('تم اختيار الإسكندرية'), findsOneWidget);
    });

    testWidgets('no match says so', (tester) async {
      when(() => search.state).thenReturn(const CitySearchState(query: 'zzz'));
      await pump(tester, const Size(1440, 2800));

      expect(find.text('لا توجد مدينة بهذا الاسم في القائمة.'), findsOneWidget);
    });

    testWidgets('choosing the Hanafi school saves it', (tester) async {
      await pump(tester, const Size(1440, 2800));

      await tester.tap(find.bySemanticsLabel(RegExp('^مذهب العصر')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الحنفي'));
      await tester.pumpAndSettle();

      verify(
        () => prayer.changeSettings(
          const PrayerSettings(school: AsrSchool.hanafi),
        ),
      ).called(1);
    });

    testWidgets('choosing a method saves its Aladhan id', (tester) async {
      await pump(tester, const Size(1440, 2800));

      await tester.tap(find.bySemanticsLabel(RegExp('^طريقة الحساب')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('جامعة أم القرى، مكة المكرمة'));
      await tester.pumpAndSettle();

      verify(
        () => prayer.changeSettings(const PrayerSettings(method: 4)),
      ).called(1);
    });

    testWidgets('minute steps are saved once the user pauses', (tester) async {
      await pump(tester, const Size(1440, 2800));

      final plus = find.byTooltip('زيادة العشاء');
      await tester.ensureVisible(plus);
      await tester.tap(plus);
      await tester.tap(plus);
      await tester.pump();
      expect(find.text('+2 د'), findsOneWidget);
      verifyNever(() => prayer.changeSettings(any()));

      await tester.pump(const Duration(seconds: 1));
      verify(
        () =>
            prayer.changeSettings(const PrayerSettings(tune: {Prayer.isha: 2})),
      ).called(1);
    });

    testWidgets('the Hijri offset stops at two days', (tester) async {
      when(() => prayer.state).thenReturn(
        PrayerTimesState(
          status: PrayerTimesStatus.success,
          times: cairoTimes(10, 2),
          settings: const PrayerSettings(hijriOffset: 2),
        ),
      );
      await pump(tester, const Size(1440, 2800));

      final plus = find.ancestor(
        of: find.byTooltip('زيادة تعديل التاريخ الهجري'),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(plus).onPressed, isNull);
      expect(find.text('متقدم يومين'), findsOneWidget);
    });

    testWidgets('restoring defaults asks first, then keeps the city', (
      tester,
    ) async {
      when(() => prayer.state).thenReturn(
        PrayerTimesState(
          status: PrayerTimesStatus.success,
          times: cairoTimes(10, 2),
          settings: const PrayerSettings(school: AsrSchool.hanafi),
        ),
      );
      await pump(tester, const Size(1440, 2800));

      await tester.ensureVisible(find.text('استعادة الافتراضي'));
      await tester.tap(find.text('استعادة الافتراضي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      verifyNever(() => prayer.changeSettings(any()));

      await tester.tap(find.text('استعادة الافتراضي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('استعادة'));
      await tester.pumpAndSettle();
      verify(() => prayer.changeSettings(const PrayerSettings())).called(1);
      verifyNever(() => prayer.changeLocation(any()));
    });

    testWidgets('on phones options open in a sheet', (tester) async {
      await pump(tester, const Size(390, 4000));

      await tester.tap(find.bySemanticsLabel(RegExp('^خطوط العرض العالية')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('سُبع الليل'), findsOneWidget);
    });

    for (final width in [360.0, 390.0]) {
      for (final scale in [1.15, 1.3]) {
        testWidgets('fits a ${scale}x system font at $width', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pump(tester, Size(width, 5000));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('survives the zero-width first frame', (tester) async {
      await pump(tester, const Size(0, 800));
      expect(tester.takeException(), isNull);
    });

    testWidgets('selection fields are tall enough to tap', (tester) async {
      await pump(tester, const Size(1440, 2800));
      for (final field in tester.widgetList(find.byType(InkWell))) {
        final finder = find.byWidget(field);
        if (find
            .ancestor(
              of: finder,
              matching: find.byType(PrayerSelectField<AsrSchool>),
            )
            .evaluate()
            .isEmpty) {
          continue;
        }
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(44));
      }
    });
  });
}
