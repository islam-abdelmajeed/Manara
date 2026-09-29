import 'package:flutter/material.dart';

/// Temporary base theme. Colors, typography, spacing, radii and shadows
/// will come from the Figma design system (AppColors, AppTypography,
/// AppSpacing, AppRadius, AppShadows) and be wired in here.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      );
}
