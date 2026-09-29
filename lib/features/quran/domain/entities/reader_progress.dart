import 'package:equatable/equatable.dart';

/// Where the user is and what they saved, persisted between launches.
class ReaderProgress extends Equatable {
  const ReaderProgress({
    this.lastPage = 1,
    this.recentPages = const [],
    this.bookmarkedPages = const [],
  });

  static const int maxRecent = 10;

  final int lastPage;

  /// Most recently read pages, newest first, without duplicates.
  final List<int> recentPages;

  /// Bookmarked ("favorite") pages, in the order they were added.
  final List<int> bookmarkedPages;

  bool isBookmarked(int page) => bookmarkedPages.contains(page);

  @override
  List<Object?> get props => [lastPage, recentPages, bookmarkedPages];
}
