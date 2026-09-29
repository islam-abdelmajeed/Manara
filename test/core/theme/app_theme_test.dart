import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/theme/theme.dart';

void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light;

    test('uses the Figma primary green and cream background', () {
      expect(theme.colorScheme.primary, const Color(0xFF425841));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F0E6));
    });

    test('uses Tajawal for every text style', () {
      final styles = [
        theme.textTheme.displayLarge,
        theme.textTheme.headlineMedium,
        theme.textTheme.titleLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.labelLarge,
      ];
      for (final style in styles) {
        expect(style?.fontFamily, AppTypography.fontFamily);
      }
    });

    test('text styles match Figma sizes and line heights', () {
      expect(AppTypography.displayBold.fontSize, 32);
      expect(AppTypography.displayBold.height! * 32, 40);
      expect(AppTypography.captionRegular.fontSize, 14);
      expect(AppTypography.captionRegular.height! * 14, 20);
      expect(AppTypography.h4Regular.height! * 24, 32);
    });
  });
}
