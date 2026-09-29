import 'package:flutter/painting.dart';

/// Text styles from the Figma text styles (Tajawal, 400 / 500 / 700).
///
/// Names follow Figma: `<role><Weight>` where the role encodes the size,
/// e.g. `h1Bold` = "30 H1/30B". Colors are applied by the theme or widget.
abstract final class AppTypography {
  static const String fontFamily = 'Tajawal';

  /// Font used for Quran text (Figma: Amiri Quran 36 / line height 97).
  static const String quranFontFamily = 'AmiriQuran';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;

  // 32 Display
  static const TextStyle displayBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: bold,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: medium,
  );
  static const TextStyle displayRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: regular,
  );

  // 30 H1
  static const TextStyle h1Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    height: 40 / 30,
    fontWeight: bold,
  );
  static const TextStyle h1Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    height: 40 / 30,
    fontWeight: medium,
  );
  static const TextStyle h1Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    height: 40 / 30,
    fontWeight: regular,
  );

  // 28 H2
  static const TextStyle h2Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: bold,
  );
  static const TextStyle h2Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: medium,
  );
  static const TextStyle h2Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: regular,
  );

  // 26 H3
  static const TextStyle h3Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 34 / 26,
    fontWeight: bold,
  );
  static const TextStyle h3Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 34 / 26,
    fontWeight: medium,
  );
  static const TextStyle h3Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 34 / 26,
    fontWeight: regular,
  );

  // 24 H4 — Figma uses 28 line height for B/M and 32 for R.
  static const TextStyle h4Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 28 / 24,
    fontWeight: bold,
  );
  static const TextStyle h4Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 28 / 24,
    fontWeight: medium,
  );
  static const TextStyle h4Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: regular,
  );

  // 22 H5
  static const TextStyle h5Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 30 / 22,
    fontWeight: bold,
  );
  static const TextStyle h5Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 30 / 22,
    fontWeight: medium,
  );
  static const TextStyle h5Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 30 / 22,
    fontWeight: regular,
  );

  // 20 Subtitle — Figma defines B and M only.
  static const TextStyle subtitleBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: bold,
  );
  static const TextStyle subtitleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: medium,
  );

  // 18 Body large
  static const TextStyle bodyLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: bold,
  );
  static const TextStyle bodyLargeMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: medium,
  );
  static const TextStyle bodyLargeRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: regular,
  );

  // 16 Body — Figma uses 20 line height for M and 24 for B/R.
  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: bold,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: medium,
  );
  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: regular,
  );

  // 14 Caption
  static const TextStyle captionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: bold,
  );
  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: medium,
  );
  static const TextStyle captionRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: regular,
  );

  // Small sizes used by chips, badges and input labels (not Figma styles).
  static const TextStyle labelBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: bold,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: medium,
  );
  static const TextStyle labelRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: regular,
  );
  static const TextStyle smallBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: bold,
  );
  static const TextStyle smallMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: medium,
  );
  static const TextStyle smallRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: regular,
  );

  /// Button label from the Button / Primary and Secondary components.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: bold,
  );

  /// Base Quran text style at the Figma desktop size; scaled by the reader.
  static const TextStyle quran = TextStyle(
    fontFamily: quranFontFamily,
    fontSize: 36,
    height: 97 / 36,
    fontWeight: regular,
  );
}
