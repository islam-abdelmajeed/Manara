part of 'quran_index_cubit.dart';

enum QuranIndexStatus { initial, loading, success, failure }

/// Tabs of the Quran index, in reading order.
enum QuranIndexTab {
  surahs('السور'),
  juz('الأجزاء'),
  recent('قرئ مؤخراً'),
  favorites('المفضلة');

  const QuranIndexTab(this.label);

  final String label;
}

/// Where the reader stopped: the first ayah of the last read page.
class LastReadPosition extends Equatable {
  const LastReadPosition({required this.surah, required this.ayahNumber});

  final Surah surah;
  final int ayahNumber;

  @override
  List<Object?> get props => [surah, ayahNumber];
}

class QuranIndexState extends Equatable {
  const QuranIndexState({
    this.status = QuranIndexStatus.initial,
    this.surahs = const [],
    this.progress = const ReaderProgress(),
    this.today,
    this.lastRead,
    this.tab = QuranIndexTab.surahs,
    this.query = '',
    this.visibleCount = pageSize,
    this.errorMessage,
  });

  /// Cards added by each "عرض المزيد" (six rows of four on desktop).
  static const int pageSize = 24;

  final QuranIndexStatus status;
  final List<Surah> surahs;
  final ReaderProgress progress;

  /// Day the daily wird is measured on; set by `load`.
  final DateTime? today;

  /// `null` before any reading, or while the last page loads.
  final LastReadPosition? lastRead;
  final QuranIndexTab tab;
  final String query;
  final int visibleCount;
  final String? errorMessage;

  /// Surahs matching [query] by name (ignoring tashkeel and hamza forms) or
  /// by number.
  List<Surah> get filteredSurahs {
    final q = ArabicSearch.normalize(query);
    if (q.isEmpty) return surahs;
    final number = int.tryParse(q);
    return [
      for (final surah in surahs)
        if (surah.id == number ||
            ArabicSearch.normalize(surah.nameArabic).contains(q))
          surah,
    ];
  }

  int get pagesReadToday {
    final day = today;
    return day == null ? 0 : progress.pagesReadOn(day);
  }

  double get wirdProgress {
    final day = today;
    return day == null ? 0 : progress.wirdProgressOn(day);
  }

  /// Surah that [page] starts in.
  Surah? surahAtPage(int page) {
    Surah? found;
    for (final surah in surahs) {
      if (surah.firstPage > page) break;
      found = surah;
    }
    return found;
  }

  QuranIndexState copyWith({
    QuranIndexStatus? status,
    List<Surah>? surahs,
    ReaderProgress? progress,
    DateTime? today,
    LastReadPosition? Function()? lastRead,
    QuranIndexTab? tab,
    String? query,
    int? visibleCount,
    String? Function()? errorMessage,
  }) {
    return QuranIndexState(
      status: status ?? this.status,
      surahs: surahs ?? this.surahs,
      progress: progress ?? this.progress,
      today: today ?? this.today,
      lastRead: lastRead != null ? lastRead() : this.lastRead,
      tab: tab ?? this.tab,
      query: query ?? this.query,
      visibleCount: visibleCount ?? this.visibleCount,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    surahs,
    progress,
    today,
    lastRead,
    tab,
    query,
    visibleCount,
    errorMessage,
  ];
}
