import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  const Ayah({
    required this.surahNumber,
    required this.number,
    required this.text,
    required this.pageNumber,
    required this.juzNumber,
  });

  final int surahNumber;

  /// Ayah number inside its surah (1-based).
  final int number;

  /// Uthmani text without the end-of-ayah marker.
  final String text;
  final int pageNumber;
  final int juzNumber;

  /// Stable key, e.g. `2:255`.
  String get key => '$surahNumber:$number';

  @override
  List<Object?> get props => [surahNumber, number, text, pageNumber, juzNumber];
}
