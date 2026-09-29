import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/domain/usecases/get_mushaf_page.dart';
import 'package:manara/features/quran/domain/usecases/get_surahs.dart';
import 'package:manara/features/quran/domain/usecases/reader_progress_usecases.dart';
import 'package:manara/features/quran/presentation/utils/quran_labels.dart';

part 'quran_reader_state.dart';

@injectable
class QuranReaderCubit extends Cubit<QuranReaderState> {
  QuranReaderCubit(
    this._getSurahs,
    this._getPage,
    this._getProgress,
    this._recordVisit,
    this._toggleBookmark,
  ) : super(const QuranReaderState());

  final GetSurahs _getSurahs;
  final GetMushafPage _getPage;
  final GetReaderProgress _getProgress;
  final RecordPageVisit _recordVisit;
  final ToggleBookmark _toggleBookmark;

  /// Identifies the latest page request so slow, stale responses are dropped.
  int _requestId = 0;

  /// Loads the surah list and progress, then opens the last read page
  /// (or [initialPage] when given).
  Future<void> init({int? initialPage}) async {
    emit(state.copyWith(status: ReaderStatus.loading));

    final progress = (await _getProgress(
      const NoParams(),
    )).getOrElse((_) => const ReaderProgress());
    final surahs = (await _getSurahs(
      const NoParams(),
    )).getOrElse((_) => const <Surah>[]);
    emit(state.copyWith(progress: progress, surahs: surahs));

    await goToPage(initialPage ?? progress.lastPage);
  }

  Future<void> goToPage(int pageNumber) async {
    final target = pageNumber.clamp(
      MushafPage.firstNumber,
      MushafPage.lastNumber,
    );
    final request = ++_requestId;
    emit(
      state.copyWith(
        status: ReaderStatus.loading,
        pageNumber: target,
        selectedAyahKey: () => null,
        errorMessage: () => null,
      ),
    );

    final result = await _getPage(target);
    if (request != _requestId || isClosed) return;

    await result.match(
      (failure) async => emit(
        state.copyWith(
          status: ReaderStatus.failure,
          errorMessage: () => failure.message,
        ),
      ),
      (page) async {
        emit(state.copyWith(status: ReaderStatus.success, page: page));
        final progress = await _recordVisit(target);
        progress.match((_) {}, (p) {
          if (!isClosed && request == _requestId) {
            emit(state.copyWith(progress: p));
          }
        });
        _prefetch(target + 1);
      },
    );
  }

  Future<void> retry() => state.page == null && state.surahs.isEmpty
      ? init(initialPage: state.pageNumber)
      : goToPage(state.pageNumber);

  Future<void> nextPage() =>
      state.hasNext ? goToPage(state.pageNumber + 1) : Future<void>.value();

  Future<void> previousPage() =>
      state.hasPrevious ? goToPage(state.pageNumber - 1) : Future<void>.value();

  Future<void> goToSurah(Surah surah) => goToPage(surah.firstPage);

  /// [juz] is 1-based (1..30).
  Future<void> goToJuz(int juz) {
    return goToPage(QuranLabels.juzStartPages[juz - 1]);
  }

  void selectAyah(String? key) {
    emit(
      state.copyWith(
        selectedAyahKey: () => state.selectedAyahKey == key ? null : key,
      ),
    );
  }

  Future<void> toggleBookmark() async {
    final result = await _toggleBookmark(state.pageNumber);
    result.match(
      (_) {},
      (progress) => emit(state.copyWith(progress: progress)),
    );
  }

  void selectTab(ReaderTab tab) => emit(state.copyWith(tab: tab));

  void openPanel(ReaderPanel panel) {
    emit(
      state.copyWith(panel: state.panel == panel ? ReaderPanel.none : panel),
    );
  }

  void closePanel() => emit(state.copyWith(panel: ReaderPanel.none));

  void _prefetch(int pageNumber) {
    if (pageNumber > MushafPage.lastNumber) return;
    // Result intentionally ignored: the repository caches successful loads.
    _getPage(pageNumber);
  }
}
