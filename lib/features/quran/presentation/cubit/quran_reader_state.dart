part of 'quran_reader_cubit.dart';

enum ReaderStatus { initial, loading, success, failure }

enum ReaderTab { reading, tafsir, translation, tarteel }

/// Which side panel (or bottom sheet on small screens) is open.
enum ReaderPanel { none, navigation, settings }

class QuranReaderState extends Equatable {
  const QuranReaderState({
    this.status = ReaderStatus.initial,
    this.pageNumber = 1,
    this.page,
    this.surahs = const [],
    this.progress = const ReaderProgress(),
    this.selectedAyahKey,
    this.tab = ReaderTab.reading,
    this.panel = ReaderPanel.none,
    this.errorMessage,
  });

  final ReaderStatus status;
  final int pageNumber;

  /// The loaded page; `null` until the first page arrives.
  final MushafPage? page;
  final List<Surah> surahs;
  final ReaderProgress progress;

  /// Key (`surah:ayah`) of the highlighted ayah.
  final String? selectedAyahKey;
  final ReaderTab tab;
  final ReaderPanel panel;
  final String? errorMessage;

  bool get isBookmarked => progress.isBookmarked(pageNumber);

  bool get hasPrevious => pageNumber > MushafPage.firstNumber;

  bool get hasNext => pageNumber < MushafPage.lastNumber;

  /// Surah shown in the header: the one the current page starts in.
  Surah? get currentSurah {
    final current = page;
    if (current == null || current.ayahs.isEmpty) return null;
    for (final surah in surahs) {
      if (surah.id == current.firstSurahNumber) return surah;
    }
    return null;
  }

  QuranReaderState copyWith({
    ReaderStatus? status,
    int? pageNumber,
    MushafPage? page,
    List<Surah>? surahs,
    ReaderProgress? progress,
    String? Function()? selectedAyahKey,
    ReaderTab? tab,
    ReaderPanel? panel,
    String? Function()? errorMessage,
  }) {
    return QuranReaderState(
      status: status ?? this.status,
      pageNumber: pageNumber ?? this.pageNumber,
      page: page ?? this.page,
      surahs: surahs ?? this.surahs,
      progress: progress ?? this.progress,
      selectedAyahKey: selectedAyahKey != null
          ? selectedAyahKey()
          : this.selectedAyahKey,
      tab: tab ?? this.tab,
      panel: panel ?? this.panel,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pageNumber,
    page,
    surahs,
    progress,
    selectedAyahKey,
    tab,
    panel,
    errorMessage,
  ];
}
