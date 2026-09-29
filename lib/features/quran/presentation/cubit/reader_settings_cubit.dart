import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/usecases/reader_settings_usecases.dart';

/// Holds the reader's display preferences and persists every change.
@injectable
class ReaderSettingsCubit extends Cubit<ReaderSettings> {
  ReaderSettingsCubit(this._getSettings, this._saveSettings)
    : super(const ReaderSettings());

  final GetReaderSettings _getSettings;
  final SaveReaderSettings _saveSettings;

  Future<void> load() async {
    final result = await _getSettings(const NoParams());
    result.match((_) {}, emit);
  }

  Future<void> setFontScale(double value) {
    return _update(state.copyWith(fontScale: value));
  }

  Future<void> setLineSpacing(LineSpacing value) {
    return _update(state.copyWith(lineSpacing: value));
  }

  Future<void> setFont(MushafFont value) {
    return _update(state.copyWith(font: value));
  }

  Future<void> setTextColor(int index) {
    return _update(state.copyWith(textColorIndex: index));
  }

  Future<void> setBackgroundColor(int index) {
    return _update(state.copyWith(backgroundColorIndex: index));
  }

  Future<void> setShowStopMarks(bool value) {
    return _update(state.copyWith(showStopMarks: value));
  }

  Future<void> setShowTashkeel(bool value) {
    return _update(state.copyWith(showTashkeel: value));
  }

  Future<void> setHighlightWhilePlaying(bool value) {
    return _update(state.copyWith(highlightWhilePlaying: value));
  }

  Future<void> _update(ReaderSettings next) async {
    if (next == state) return;
    emit(next);
    await _saveSettings(next);
  }
}
