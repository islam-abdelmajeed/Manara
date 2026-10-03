import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/core/utils/arabic_search.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/domain/usecases/get_mushaf_page.dart';
import 'package:manara/features/quran/domain/usecases/get_surahs.dart';
import 'package:manara/features/quran/domain/usecases/reader_progress_usecases.dart';

part 'quran_index_state.dart';

/// Quran index (Figma "Desktop - 4"): surah / juz / recent / favorites
/// lists, search, and the reading summary cards.
@injectable
class QuranIndexCubit extends Cubit<QuranIndexState> {
  QuranIndexCubit(this._getSurahs, this._getProgress, this._getPage)
    : super(const QuranIndexState());

  final GetSurahs _getSurahs;
  final GetReaderProgress _getProgress;
  final GetMushafPage _getPage;

  Future<void> load({DateTime? now}) async {
    emit(
      state.copyWith(
        status: QuranIndexStatus.loading,
        today: now ?? DateTime.now(),
        errorMessage: () => null,
      ),
    );

    final progress = (await _getProgress(
      const NoParams(),
    )).getOrElse((_) => const ReaderProgress());
    final surahs = await _getSurahs(const NoParams());
    if (isClosed) return;

    surahs.match(
      (failure) => emit(
        state.copyWith(
          status: QuranIndexStatus.failure,
          progress: progress,
          errorMessage: () => failure.message,
        ),
      ),
      (list) => emit(
        state.copyWith(
          status: QuranIndexStatus.success,
          surahs: list,
          progress: progress,
        ),
      ),
    );

    if (progress.hasStarted) await _loadLastRead(progress.lastPage);
  }

  /// Re-reads progress, e.g. when coming back from the reader, without
  /// reloading the surah list.
  Future<void> refreshProgress({DateTime? now}) async {
    final result = await _getProgress(const NoParams());
    if (isClosed) return;
    final progress = result.getOrElse((_) => state.progress);
    emit(state.copyWith(progress: progress, today: now ?? DateTime.now()));
    if (progress.hasStarted) await _loadLastRead(progress.lastPage);
  }

  void selectTab(QuranIndexTab tab) {
    if (tab == state.tab) return;
    emit(state.copyWith(tab: tab, visibleCount: QuranIndexState.pageSize));
  }

  /// Search covers surahs, so a query brings their tab forward.
  void search(String query) {
    emit(
      state.copyWith(
        query: query,
        tab: query.trim().isEmpty ? null : QuranIndexTab.surahs,
        visibleCount: QuranIndexState.pageSize,
      ),
    );
  }

  void showMore() {
    emit(
      state.copyWith(
        visibleCount: state.visibleCount + QuranIndexState.pageSize,
      ),
    );
  }

  Future<void> _loadLastRead(int page) async {
    final result = await _getPage(page);
    if (isClosed) return;
    result.match((_) {}, (loaded) {
      if (loaded.ayahs.isEmpty) return;
      final first = loaded.ayahs.first;
      final surah = state.surahs.where((s) => s.id == first.surahNumber);
      if (surah.isEmpty) return;
      emit(
        state.copyWith(
          lastRead: () =>
              LastReadPosition(surah: surah.first, ayahNumber: first.number),
        ),
      );
    });
  }
}
