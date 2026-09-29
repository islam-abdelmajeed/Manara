import 'package:flutter/painting.dart';
import 'package:manara/core/theme/theme.dart';

/// Colors offered in the reader settings.
///
/// Figma shows six empty circles for each row (all `#D9D9D9` placeholders),
/// so the swatches are picked from the Manara palette. The first entry of
/// each list is the default and matches the Figma reader screens.
abstract final class ReaderPalette {
  static const List<Color> textColors = [
    Color(0xFF000000),
    AppColors.darkBrown500,
    AppColors.green900,
    AppColors.green700,
    AppColors.gold800,
    AppColors.darkBrown900,
  ];

  static const List<Color> backgroundColors = [
    AppColors.readerBackground,
    AppColors.white50,
    AppColors.ivory500,
    AppColors.beige500,
    AppColors.cream400,
    AppColors.green50,
  ];

  static Color text(int index) => _at(textColors, index);

  static Color background(int index) => _at(backgroundColors, index);

  static Color _at(List<Color> colors, int index) {
    return colors[index.clamp(0, colors.length - 1)];
  }
}
