import 'package:equatable/equatable.dart';

class Hadith extends Equatable {
  const Hadith({required this.text, required this.source});

  /// The Prophet's words, without the opening "قال رسول الله ﷺ".
  final String text;

  /// e.g. `رواه مسلم`.
  final String source;

  @override
  List<Object?> get props => [text, source];
}
