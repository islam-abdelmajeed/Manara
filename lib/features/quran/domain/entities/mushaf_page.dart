import 'package:equatable/equatable.dart';
import 'package:manara/features/quran/domain/entities/ayah.dart';

/// One page of the Madani Mushaf.
class MushafPage extends Equatable {
  const MushafPage({required this.number, required this.ayahs});

  static const int firstNumber = 1;
  static const int lastNumber = 604;

  /// First page of each juz (1..30).
  static const List<int> juzStartPages = [
    1, 22, 42, 62, 82, 102, 122, 142, 162, 182, //
    202, 222, 242, 262, 282, 302, 322, 342, 362, 382,
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];

  /// Juz (1..30) that [page] belongs to.
  static int juzOf(int page) {
    var juz = 1;
    for (var i = 0; i < juzStartPages.length; i++) {
      if (juzStartPages[i] <= page) juz = i + 1;
    }
    return juz;
  }

  final int number;
  final List<Ayah> ayahs;

  /// Surah the page starts in; used for the reader header.
  int get firstSurahNumber => ayahs.first.surahNumber;

  @override
  List<Object?> get props => [number, ayahs];
}
