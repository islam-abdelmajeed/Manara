import 'package:flutter/painting.dart';

/// Corner radii used across the Figma components and screens.
abstract final class AppRadius {
  /// Small buttons, navbar.
  static const double sm = 10;

  /// Default: buttons, inputs, cards, tiles.
  static const double md = 12;

  /// Large cards (room card, create-room banner).
  static const double lg = 16;

  /// Hero sections and pill search field.
  static const double xl = 24;

  /// Fully rounded chips and badges.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
