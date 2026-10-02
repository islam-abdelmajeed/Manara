import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/quran/presentation/widgets/index/index_style.dart';

/// One tile of the index grid: number badge, name and a detail line
/// (Figma: 226×106 surah card).
class QuranIndexCard extends StatelessWidget {
  const QuranIndexCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  /// Figma height at the default font size; the card grows past it.
  static const double height = 106;

  final int number;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$number، $title، $subtitle',
      excludeSemantics: true,
      child: Material(
        color: IndexStyle.cardColor,
        shape: IndexStyle.cardShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.primary.withValues(alpha: 0.04),
          // The Figma height is a minimum: a larger system font grows the
          // card instead of clipping the detail line.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NumberBadge(number: number),
                  const SizedBox(height: 13),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subtitleBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionRegular.copyWith(
                      fontSize: 13,
                      color: IndexStyle.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 13),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: const ShapeDecoration(
        color: AppColors.readerBackground,
        shape: StadiumBorder(),
      ),
      child: Text(
        textAlign: TextAlign.center,
        '$number',
        style: AppTypography.labelBold.copyWith(
          color: AppColors.primary,
          height: 1,
        ),
      ),
    );
  }
}
