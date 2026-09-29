import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';
import 'package:manara/features/hadith/domain/usecases/get_hadith_of_the_day.dart';
import 'package:manara/features/home/presentation/cubit/home_cubit.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/usecases/reader_progress_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockGetHadith extends Mock implements GetHadithOfTheDay {}

class MockGetProgress extends Mock implements GetReaderProgress {}

void main() {
  late MockGetHadith getHadith;
  late MockGetProgress getProgress;
  final today = DateTime(2026, 9, 29, 10);
  const hadith = Hadith(text: 'نص', source: 'رواه مسلم');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    getHadith = MockGetHadith();
    getProgress = MockGetProgress();
  });

  test('loads the hadith, progress and streak', () async {
    when(() => getHadith(any())).thenAnswer((_) async => const Right(hadith));
    when(() => getProgress(any())).thenAnswer(
      (_) async => Right(
        ReaderProgress(
          lastPage: 50,
          recentPages: const [50],
          readingDays: [DateTime(2026, 9, 29), DateTime(2026, 9, 28)],
        ),
      ),
    );
    final cubit = HomeCubit(getHadith, getProgress);

    await cubit.load(now: today);

    expect(cubit.state.hadith, hadith);
    expect(cubit.state.progress.currentJuz, 3);
    expect(cubit.state.streak, 2);
    verify(() => getHadith(today)).called(1);
  });

  test('failures leave empty but valid content', () async {
    when(
      () => getHadith(any()),
    ).thenAnswer((_) async => const Left(UnexpectedFailure()));
    when(
      () => getProgress(any()),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    final cubit = HomeCubit(getHadith, getProgress);

    await cubit.load(now: today);

    expect(cubit.state.hadith, isNull);
    expect(cubit.state.progress, const ReaderProgress());
    expect(cubit.state.streak, 0);
  });
}
