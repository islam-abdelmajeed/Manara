import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';
import 'package:manara/features/hadith/domain/usecases/get_hadith_of_the_day.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/usecases/reader_progress_usecases.dart';

class HomeState extends Equatable {
  const HomeState({
    this.hadith,
    this.progress = const ReaderProgress(),
    this.streak = 0,
  });

  final Hadith? hadith;
  final ReaderProgress progress;

  /// Consecutive reading days, ending today or yesterday.
  final int streak;

  @override
  List<Object?> get props => [hadith, progress, streak];
}

/// Local content of the home page: hadith of the day and reading progress.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHadith, this._getProgress) : super(const HomeState());

  final GetHadithOfTheDay _getHadith;
  final GetReaderProgress _getProgress;

  Future<void> load({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final hadith = await _getHadith(today);
    final progress = await _getProgress(const NoParams());
    if (isClosed) return;

    final p = progress.getOrElse((_) => const ReaderProgress());
    emit(
      HomeState(
        hadith: hadith.toNullable(),
        progress: p,
        streak: p.streakOn(today),
      ),
    );
  }
}
