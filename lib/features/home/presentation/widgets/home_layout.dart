import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';

/// Measurements of the Figma home frame ("Desktop - 1", 1440 wide).
abstract final class HomeLayout {
  /// Width of the content column between the 36px side margins.
  static const double contentWidth = 1368;

  /// Below this content width the paired cards stack vertically.
  static const double twoColumnMinWidth = 1100;

  /// Horizontal page padding that centers the content column.
  static double sidePadding(double screenWidth) {
    if (screenWidth < 600) return AppSpacing.md;
    if (screenWidth < 1000) return AppSpacing.xl;
    return math.max(36, (screenWidth - contentWidth) / 2);
  }

  static bool isWide(double screenWidth) =>
      screenWidth - 2 * sidePadding(screenWidth) >= twoColumnMinWidth;
}

/// Section heading ("الوصول السريع", "كنوز منارة"): 32 bold green, aligned to
/// the reading start.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {this.padding = 10, super.key});

  final String title;

  /// Figma wraps "الوصول السريع" in 10px of padding; "كنوز منارة" has none.
  final double padding;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            title,
            style: (compact ? AppTypography.h4Bold : AppTypography.displayBold)
                .copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
