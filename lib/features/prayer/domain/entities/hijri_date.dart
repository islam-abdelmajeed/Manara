import 'package:equatable/equatable.dart';

/// A Hijri date as Aladhan calculates it (HJCoSA calendar by default).
class HijriDate extends Equatable {
  const HijriDate({required this.day, required this.month, required this.year})
    : assert(month >= 1 && month <= 12, 'month is 1-12');

  /// Month names without diacritics. Aladhan's own Arabic names carry
  /// diacritics and some arrive with broken characters, so they are not used.
  static const List<String> monthNames = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  final int day;
  final int month;
  final int year;

  String get monthName => monthNames[month - 1];

  /// e.g. `21 ربيع الثاني 1448 هـ`.
  String get label => '$day $monthName $year هـ';

  /// e.g. `21/4`, as in the monthly table.
  String get shortLabel => '$day/$month';

  @override
  List<Object?> get props => [day, month, year];
}
