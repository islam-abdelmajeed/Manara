import 'package:equatable/equatable.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';

/// Where the user is and what they saved, persisted between launches.
class ReaderProgress extends Equatable {
  const ReaderProgress({
    this.lastPage = 1,
    this.recentPages = const [],
    this.bookmarkedPages = const [],
    this.readingDays = const [],
  });

  static const int maxRecent = 10;
  static const int maxReadingDays = 60;

  final int lastPage;

  /// Most recently read pages, newest first, without duplicates.
  final List<int> recentPages;

  /// Bookmarked ("favorite") pages, in the order they were added.
  final List<int> bookmarkedPages;

  /// Days the reader was opened, newest first, as local calendar dates.
  final List<DateTime> readingDays;

  bool get hasStarted => recentPages.isNotEmpty;

  bool isBookmarked(int page) => bookmarkedPages.contains(page);

  /// Juz (1..30) of the last read page, or 0 before any reading.
  int get currentJuz => hasStarted ? MushafPage.juzOf(lastPage) : 0;

  /// Consecutive reading days ending [today], or yesterday when today has
  /// no reading yet (the streak is still alive until the day ends).
  int streakOn(DateTime today) {
    final days = {for (final d in readingDays) _dateOnly(d)};
    var day = _dateOnly(today);
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  ReaderProgress copyWith({
    int? lastPage,
    List<int>? recentPages,
    List<int>? bookmarkedPages,
    List<DateTime>? readingDays,
  }) {
    return ReaderProgress(
      lastPage: lastPage ?? this.lastPage,
      recentPages: recentPages ?? this.recentPages,
      bookmarkedPages: bookmarkedPages ?? this.bookmarkedPages,
      readingDays: readingDays ?? this.readingDays,
    );
  }

  @override
  List<Object?> get props => [
    lastPage,
    recentPages,
    bookmarkedPages,
    readingDays,
  ];
}
