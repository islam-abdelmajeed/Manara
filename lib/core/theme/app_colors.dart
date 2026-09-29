import 'package:flutter/painting.dart';

/// Color tokens from the Figma "Design System - منارة" page.
///
/// Scales mirror the `Manara/<Scale>/<Shade>` color styles one-to-one.
/// Semantic tokens map each role to the value used across the screens.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Semantic tokens — use these in widgets.
  // ---------------------------------------------------------------------------

  static const Color primary = green700;
  static const Color onPrimary = white50;

  /// Page background.
  static const Color background = cream400;

  /// Cards, inputs, sheets.
  static const Color surface = white50;

  /// Hero sections, selected cards, member/share tiles.
  static const Color surfaceMuted = cream500;

  /// Selected list item background.
  static const Color surfaceSelected = beige500;

  static const Color textPrimary = Color(0xFF1A261F);
  static const Color textSecondary = Color(0xFF5E6B63);
  static const Color textOnPrimary = white50;

  /// Search field placeholder.
  static const Color textHint = Color(0xFF9C8B6F);

  static const Color icon = green900;
  static const Color border = Color(0xFFC2C4B2);

  /// Pill-shaped search field outline.
  static const Color borderStrong = darkBrown400;

  static const Color liveBackground = Color(0xFFDBEDDB);
  static const Color liveForeground = Color(0xFF338047);
  static const Color liveDot = Color(0xFF4A8C52);
  static const Color endedBackground = Color(0xFFEBE8E0);

  /// Circular icon holder on room cards.
  static const Color avatarBackground = Color(0xFFEDE8D9);

  // ---------------------------------------------------------------------------
  // Scales — Manara/<Scale>/<Shade>.
  // ---------------------------------------------------------------------------

  static const Color green50 = Color(0xFFF4F6F3);
  static const Color green100 = Color(0xFFE5EAE5);
  static const Color green200 = Color(0xFFCBD4CA);
  static const Color green300 = Color(0xFFADBCAC);
  static const Color green400 = Color(0xFF869D85);
  static const Color green500 = Color(0xFF5C7A5A);
  static const Color green600 = Color(0xFF4F694D);
  static const Color green700 = Color(0xFF425841);
  static const Color green800 = Color(0xFF344432);
  static const Color green900 = Color(0xFF253124);

  static const Color cream50 = Color(0xFFFEFEFD);
  static const Color cream100 = Color(0xFFFDFCFA);
  static const Color cream200 = Color(0xFFFBF9F4);
  static const Color cream300 = Color(0xFFF9F5EE);
  static const Color cream400 = Color(0xFFF7F0E6);
  static const Color cream500 = Color(0xFFF4EBDD);
  static const Color cream600 = Color(0xFFD2CABE);
  static const Color cream700 = Color(0xFFB0A99F);
  static const Color cream800 = Color(0xFF89847C);
  static const Color cream900 = Color(0xFF625E58);

  static const Color beige50 = Color(0xFFFDFDFB);
  static const Color beige100 = Color(0xFFFBF9F6);
  static const Color beige200 = Color(0xFFF8F4ED);
  static const Color beige300 = Color(0xFFF4EDE3);
  static const Color beige400 = Color(0xFFEFE5D6);
  static const Color beige500 = Color(0xFFE9DCC8);
  static const Color beige600 = Color(0xFFC8BDAC);
  static const Color beige700 = Color(0xFFA89E90);
  static const Color beige800 = Color(0xFF827B70);
  static const Color beige900 = Color(0xFF5D5850);

  static const Color ivory50 = Color(0xFFFFFEFE);
  static const Color ivory100 = Color(0xFFFEFDFC);
  static const Color ivory200 = Color(0xFFFDFCF9);
  static const Color ivory300 = Color(0xFFFCFAF5);
  static const Color ivory400 = Color(0xFFFBF8F1);
  static const Color ivory500 = Color(0xFFFAF5EC);
  static const Color ivory600 = Color(0xFFD7D3CB);
  static const Color ivory700 = Color(0xFFB4B0AA);
  static const Color ivory800 = Color(0xFF8C8984);
  static const Color ivory900 = Color(0xFF64625E);

  static const Color white50 = Color(0xFFFFFFFF);
  static const Color white100 = Color(0xFFFFFFFE);
  static const Color white200 = Color(0xFFFFFEFD);
  static const Color white300 = Color(0xFFFFFEFC);
  static const Color white400 = Color(0xFFFFFEFB);
  static const Color white500 = Color(0xFFFFFDF9);
  static const Color white600 = Color(0xFFDBDAD6);
  static const Color white700 = Color(0xFFB8B6B3);
  static const Color white800 = Color(0xFF8F8E8B);
  static const Color white900 = Color(0xFF666564);

  static const Color gold50 = Color(0xFFFAF6EF);
  static const Color gold100 = Color(0xFFF4EADB);
  static const Color gold200 = Color(0xFFE8D4B8);
  static const Color gold300 = Color(0xFFDBBC8F);
  static const Color gold400 = Color(0xFFCA9C5A);
  static const Color gold500 = Color(0xFFB87920);
  static const Color gold600 = Color(0xFF9E681C);
  static const Color gold700 = Color(0xFF845717);
  static const Color gold800 = Color(0xFF674412);
  static const Color gold900 = Color(0xFF4A300D);

  static const Color lightGold50 = Color(0xFFFCF9F4);
  static const Color lightGold100 = Color(0xFFF9F0E5);
  static const Color lightGold200 = Color(0xFFF3E2CB);
  static const Color lightGold300 = Color(0xFFEBD1AD);
  static const Color lightGold400 = Color(0xFFE2BC86);
  static const Color lightGold500 = Color(0xFFD8A45C);
  static const Color lightGold600 = Color(0xFFBA8D4F);
  static const Color lightGold700 = Color(0xFF9C7642);
  static const Color lightGold800 = Color(0xFF795C34);
  static const Color lightGold900 = Color(0xFF564225);

  static const Color darkBrown50 = Color(0xFFF1F0EF);
  static const Color darkBrown100 = Color(0xFFE0DDDA);
  static const Color darkBrown200 = Color(0xFFC1BBB5);
  static const Color darkBrown300 = Color(0xFF9E948B);
  static const Color darkBrown400 = Color(0xFF6F6154);
  static const Color darkBrown500 = Color(0xFF3D2A18);
  static const Color darkBrown600 = Color(0xFF342415);
  static const Color darkBrown700 = Color(0xFF2C1E11);
  static const Color darkBrown800 = Color(0xFF22180D);
  static const Color darkBrown900 = Color(0xFF18110A);
}
