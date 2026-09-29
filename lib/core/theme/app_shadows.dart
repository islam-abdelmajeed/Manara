import 'package:flutter/painting.dart';

/// The design is flat and relies on borders; Figma defines one shadow.
abstract final class AppShadows {
  /// Drop shadow on the sticky header of the surah picker screen.
  static const List<BoxShadow> header = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 18.3),
  ];
}
