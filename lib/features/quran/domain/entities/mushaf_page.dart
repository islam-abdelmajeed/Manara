import 'package:equatable/equatable.dart';
import 'package:manara/features/quran/domain/entities/ayah.dart';

/// One page of the Madani Mushaf.
class MushafPage extends Equatable {
  const MushafPage({required this.number, required this.ayahs});

  static const int firstNumber = 1;
  static const int lastNumber = 604;

  final int number;
  final List<Ayah> ayahs;

  /// Surah the page starts in; used for the reader header.
  int get firstSurahNumber => ayahs.first.surahNumber;

  @override
  List<Object?> get props => [number, ayahs];
}
