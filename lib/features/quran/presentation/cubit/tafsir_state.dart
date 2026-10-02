part of 'tafsir_cubit.dart';

enum TafsirStatus { initial, loading, success, failure }

class TafsirState extends Equatable {
  const TafsirState({
    this.status = TafsirStatus.initial,
    this.source = TafsirSource.mukhtasar,
    this.pageNumber,
    this.sections = const [],
    this.errorMessage,
  });

  final TafsirStatus status;
  final TafsirSource source;

  /// Mushaf page the [sections] belong to (or are loading for).
  final int? pageNumber;

  /// The page's ayahs grouped with their tafsir. While another page loads
  /// these still hold the previous one.
  final List<TafsirSection> sections;
  final String? errorMessage;

  TafsirState copyWith({
    TafsirStatus? status,
    TafsirSource? source,
    int? pageNumber,
    List<TafsirSection>? sections,
    String? Function()? errorMessage,
  }) {
    return TafsirState(
      status: status ?? this.status,
      source: source ?? this.source,
      pageNumber: pageNumber ?? this.pageNumber,
      sections: sections ?? this.sections,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    source,
    pageNumber,
    sections,
    errorMessage,
  ];
}
