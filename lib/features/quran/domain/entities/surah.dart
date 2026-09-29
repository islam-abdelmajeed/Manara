import 'package:equatable/equatable.dart';

enum RevelationPlace { makkah, madinah }

class Surah extends Equatable {
  const Surah({
    required this.id,
    required this.nameArabic,
    required this.revelationPlace,
    required this.versesCount,
    required this.firstPage,
    required this.lastPage,
  });

  final int id;
  final String nameArabic;
  final RevelationPlace revelationPlace;
  final int versesCount;

  /// Mushaf page where the surah starts / ends.
  final int firstPage;
  final int lastPage;

  @override
  List<Object?> get props => [
    id,
    nameArabic,
    revelationPlace,
    versesCount,
    firstPage,
    lastPage,
  ];
}
