import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/usecases/reader_settings_usecases.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockGetReaderSettings extends Mock implements GetReaderSettings {}

class MockSaveReaderSettings extends Mock implements SaveReaderSettings {}

void main() {
  late MockGetReaderSettings getSettings;
  late MockSaveReaderSettings saveSettings;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ReaderSettings());
  });

  setUp(() {
    getSettings = MockGetReaderSettings();
    saveSettings = MockSaveReaderSettings();
    when(
      () => getSettings(any()),
    ).thenAnswer((_) async => const Right(ReaderSettings(fontScale: 1.2)));
    when(() => saveSettings(any())).thenAnswer((_) async => const Right(unit));
  });

  ReaderSettingsCubit build() => ReaderSettingsCubit(getSettings, saveSettings);

  test('starts with the defaults', () {
    expect(build().state, const ReaderSettings());
  });

  test('load replaces the state with the stored settings', () async {
    final cubit = build();
    await cubit.load();
    expect(cubit.state.fontScale, 1.2);
  });

  test('keeps the defaults when loading fails', () async {
    when(
      () => getSettings(any()),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    final cubit = build();
    await cubit.load();
    expect(cubit.state, const ReaderSettings());
  });

  test('every change is emitted and saved', () async {
    final cubit = build();

    await cubit.setLineSpacing(LineSpacing.normal);
    await cubit.setTextColor(3);
    await cubit.setBackgroundColor(2);
    await cubit.setShowTashkeel(false);

    expect(cubit.state.lineSpacing, LineSpacing.normal);
    expect(cubit.state.textColorIndex, 3);
    expect(cubit.state.backgroundColorIndex, 2);
    expect(cubit.state.showTashkeel, isFalse);
    verify(() => saveSettings(any())).called(4);
  });

  test('font scale is clamped to the allowed range', () async {
    final cubit = build();

    await cubit.setFontScale(5);
    expect(cubit.state.fontScale, ReaderSettings.maxFontScale);

    await cubit.setFontScale(0);
    expect(cubit.state.fontScale, ReaderSettings.minFontScale);
  });

  test('setting the same value does not save again', () async {
    final cubit = build();

    await cubit.setShowStopMarks(true);

    verifyNever(() => saveSettings(any()));
  });
}
