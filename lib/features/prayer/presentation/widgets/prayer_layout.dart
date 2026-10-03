import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';

/// Tabs of the prayer section, in the order shown.
enum PrayerTab {
  times('المواقيت و القبلة', AppRoutes.prayer),
  monthly('الجدول الشهري', AppRoutes.prayerMonthly),
  alerts('التنبيهات', AppRoutes.prayerAlerts),
  settings('الإعدادات', AppRoutes.prayerSettings);

  const PrayerTab(this.label, this.route);

  final String label;
  final String route;
}

/// Measurements of the Figma prayer frames (1512 wide).
abstract final class PrayerLayout {
  /// Width of the content column.
  static const double contentWidth = 1362;

  /// Below this width the screens use their phone layouts.
  static const double compactWidth = 900;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidth;

  /// Horizontal page padding that centers the content column.
  static double sidePadding(double screenWidth) {
    if (screenWidth < 600) return AppSpacing.md;
    if (screenWidth < 1000) return AppSpacing.xl;
    return math.max(36, (screenWidth - contentWidth) / 2);
  }
}

/// Section heading (e.g. "مواقيت الصلاة") with an optional description,
/// aligned to the reading start.
class PrayerSectionTitle extends StatelessWidget {
  const PrayerSectionTitle(
    this.title, {
    this.description,
    this.large = true,
    super.key,
  });

  final String title;
  final String? description;

  /// 32 bold (screen titles) or 28 regular (sub-sections).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final compact = PrayerLayout.isCompact(context);
    final titleStyle = large
        ? (compact ? AppTypography.h4Bold : AppTypography.displayBold)
        : (compact ? AppTypography.subtitleMedium : AppTypography.h2Regular);
    final description = this.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: titleStyle.copyWith(color: AppColors.textPrimary),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              description,
              style:
                  (large && !compact
                          ? AppTypography.bodyRegular
                          : AppTypography.captionRegular)
                      .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

/// A rounded box on the page background, outlined (info cards, panels).
class PrayerPanel extends StatelessWidget {
  const PrayerPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderColor = AppColors.green100,
    this.color = AppColors.readerBackground,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: borderColor),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
