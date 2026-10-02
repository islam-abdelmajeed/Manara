import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';
import 'package:manara/features/quran/domain/usecases/tafsir_usecases.dart';

part 'tafsir_state.dart';

/// Tafsir of the reader's current page in the chosen [TafsirSource].
///
/// The reader page decides which page is shown; this cubit only follows it
/// through [load], so nothing is downloaded until the tafsir tab is opened.
@injectable
class TafsirCubit extends Cubit<TafsirState> {
  TafsirCubit(this._getPageTafsir, this._getSource, this._saveSource)
    : super(const TafsirState());

  final GetPageTafsir _getPageTafsir;
  final GetTafsirSource _getSource;
  final SaveTafsirSource _saveSource;

  MushafPage? _page;

  /// Identifies the latest request so slow, stale responses are dropped.
  int _requestId = 0;

  Future<void>? _restoring;

  /// Shows the tafsir of [page]; a no-op when it is already shown or loading.
  Future<void> load(MushafPage page) async {
    await _restoreSource();
    if (isClosed) return;
    if (page == _page && state.status != TafsirStatus.failure) return;
    _page = page;
    await _fetch();
  }

  /// Switches to [source], remembers it and reloads the current page.
  Future<void> selectSource(TafsirSource source) async {
    // Restore first so the stored choice can't land after the user's.
    await _restoreSource();
    if (isClosed || source == state.source) return;
    emit(state.copyWith(source: source));
    final saving = _saveSource(source);
    if (_page != null) await _fetch();
    await saving;
  }

  Future<void> retry() => _page == null ? Future<void>.value() : _fetch();

  Future<void> _restoreSource() {
    return _restoring ??= () async {
      final result = await _getSource(const NoParams());
      result.match((_) {}, (source) {
        // Bloc lets a first emit through even when it equals the state.
        if (!isClosed && source != state.source) {
          emit(state.copyWith(source: source));
        }
      });
    }();
  }

  Future<void> _fetch() async {
    final page = _page!;
    final source = state.source;
    final request = ++_requestId;
    emit(
      state.copyWith(
        status: TafsirStatus.loading,
        pageNumber: page.number,
        errorMessage: () => null,
      ),
    );

    final result = await _getPageTafsir(
      PageTafsirParams(source: source, page: page),
    );
    if (request != _requestId || isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(
          status: TafsirStatus.failure,
          errorMessage: () => failure.message,
        ),
      ),
      (tafsir) => emit(
        state.copyWith(
          status: TafsirStatus.success,
          sections: TafsirSection.group(page.ayahs, tafsir),
        ),
      ),
    );
  }
}
