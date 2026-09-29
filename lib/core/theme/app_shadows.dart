import 'package:flutter/painting.dart';

/// The design is flat and relies on borders; Figma defines one shadow.
abstract final class AppShadows {
  /// Drop shadow on the sticky header of the surah picker screen.
  static const List<BoxShadow> header = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 18.3),
  ];

  /// Sticky header of the Mushaf card (Figma: y 4, blur 15, 25%).
  static const List<BoxShadow> mushafHeader = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 15),
  ];

  /// Selected reader tab (Figma: y 4, blur 20, 25%).
  static const List<BoxShadow> tab = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 20),
  ];
}
