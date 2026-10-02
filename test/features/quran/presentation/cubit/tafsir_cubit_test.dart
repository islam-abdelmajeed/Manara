import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';
import 'package:manara/features/quran/domain/usecases/tafsir_usecases.dart';
import 'package:manara/features/quran/presentation/cubit/tafsir_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/quran_fixtures.dart';

class MockGetPageTafsir extends Mock implements GetPageTafsir {}

class MockGetTafsirSource extends Mock implements GetTafsirSource {}

class MockSaveTafsirSource extends Mock implements SaveTafsirSource {}

List<AyahTafsir> _tafsirFor(PageTafsirParams params) => [
  for (final a in params.page.ayahs)
    AyahTafsir(
      ayahKey: a.key,
      paragraphs: ['${params.source.label} ${a.number}'],
    ),
];

void main() {
  late MockGetPageTafsir getPageTafsir;
  late MockGetTafsirSource getSource;
  late MockSaveTafsirSource saveSource;

  final page2 = pageOf(2);
  final page3 = pageOf(3, firstAyah: 6);

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(TafsirSource.mukhtasar);
    registerFallbackValue(
      PageTafsirParams(source: TafsirSource.mukhtasar, page: pageOf(1)),
    );
  });

  setUp(() {
    getPageTafsir = MockGetPageTafsir();
    getSource = MockGetTafsirSource();
    saveSource = MockSaveTafsirSource();
    when(
      () => getSource(any()),
    ).thenAnswer((_) async => const Right(TafsirSource.mukhtasar));
    when(() => saveSource(any())).thenAnswer((_) async => const Right(unit));
    when(() => getPageTafsir(any())).thenAnswer(
      (i) async =>
          Right(_tafsirFor(i.positionalArguments.first as PageTafsirParams)),
    );
  });

  TafsirCubit build() => TafsirCubit(getPageTafsir, getSource, saveSource);

  test('starts idle with Al-Mukhtasar', () {
    expect(build().state, const TafsirState());
  });

  blocTest<TafsirCubit, TafsirState>(
    'load shows the page grouped into sections',
    build: build,
    act: (cubit) => cubit.load(page2),
    expect: () => [
      const TafsirState(status: TafsirStatus.loading, pageNumber: 2),
      isA<TafsirState>()
          .having((s) => s.status, 'status', TafsirStatus.success)
          .having((s) => s.sections, 'sections', hasLength(3))
          .having((s) => s.sections.first.paragraphs, 'first tafsir', [
            'المختصر 1',
          ]),
    ],
  );

  blocTest<TafsirCubit, TafsirState>(
    'restores the stored source before the first load',
    setUp: () => when(
      () => getSource(any()),
    ).thenAnswer((_) async => const Right(TafsirSource.ibnKathir)),
    build: build,
    act: (cubit) => cubit.load(page2),
    verify: (cubit) {
      expect(cubit.state.source, TafsirSource.ibnKathir);
      expect(cubit.state.sections.first.paragraphs, ['ابن كثير 1']);
    },
  );

  blocTest<TafsirCubit, TafsirState>(
    'loading the same page again does nothing',
    build: build,
    act: (cubit) async {
      await cubit.load(page2);
      await cubit.load(page2);
    },
    verify: (_) => verify(() => getPageTafsir(any())).called(1),
  );

  blocTest<TafsirCubit, TafsirState>(
    'a failure shows its message and retry loads again',
    setUp: () {
      var calls = 0;
      when(() => getPageTafsir(any())).thenAnswer((i) async {
        if (calls++ == 0) return const Left(NetworkFailure());
        return Right(
          _tafsirFor(i.positionalArguments.first as PageTafsirParams),
        );
      });
    },
    build: build,
    act: (cubit) async {
      await cubit.load(page2);
      await cubit.retry();
    },
    expect: () => [
      const TafsirState(status: TafsirStatus.loading, pageNumber: 2),
      const TafsirState(
        status: TafsirStatus.failure,
        pageNumber: 2,
        errorMessage: 'تعذّر الاتصال بالإنترنت',
      ),
      const TafsirState(status: TafsirStatus.loading, pageNumber: 2),
      isA<TafsirState>().having(
        (s) => s.status,
        'status',
        TafsirStatus.success,
      ),
    ],
  );

  blocTest<TafsirCubit, TafsirState>(
    'selecting a source saves it and reloads the page',
    build: build,
    act: (cubit) async {
      await cubit.load(page2);
      await cubit.selectSource(TafsirSource.ibnKathir);
    },
    verify: (cubit) {
      expect(cubit.state.source, TafsirSource.ibnKathir);
      expect(cubit.state.sections.first.paragraphs, ['ابن كثير 1']);
      verify(() => saveSource(TafsirSource.ibnKathir)).called(1);
    },
  );

  blocTest<TafsirCubit, TafsirState>(
    'selecting the current source is a no-op',
    build: build,
    act: (cubit) => cubit.selectSource(TafsirSource.mukhtasar),
    expect: () => <TafsirState>[],
    verify: (_) => verifyNever(() => saveSource(any())),
  );

  test('a slow response for an old page is dropped', () async {
    final slow = Completer<Either<Failure, List<AyahTafsir>>>();
    when(() => getPageTafsir(any())).thenAnswer((i) {
      final params = i.positionalArguments.first as PageTafsirParams;
      return params.page.number == 2
          ? slow.future
          : Future.value(Right(_tafsirFor(params)));
    });
    final cubit = build();

    final first = cubit.load(page2);
    await cubit.load(page3);
    slow.complete(
      Right(
        _tafsirFor(
          PageTafsirParams(source: TafsirSource.mukhtasar, page: page2),
        ),
      ),
    );
    await first;

    expect(cubit.state.pageNumber, 3);
    expect(cubit.state.sections.first.ayahs.first.key, '2:6');
    await cubit.close();
  });
}
