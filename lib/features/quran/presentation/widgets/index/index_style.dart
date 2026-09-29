import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';

/// Values shared by the Quran index widgets (Figma "Desktop - 4").
abstract final class IndexStyle {
  static const Color cardColor = AppColors.darkBrown50;
  static const Color borderColor = AppColors.darkBrown400;
  static const Color titleColor = AppColors.darkBrown500;

  /// Secondary text: card subtitles, "الآية 32", the wird hint.
  static const Color mutedText = Color(0xFF6B5A42);

  static const BorderRadius radius = BorderRadius.all(Radius.circular(14));

  static const ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: radius,
    side: BorderSide(color: borderColor),
  );
}

/// 40-high pill button used by the side cards.
class IndexPillButton extends StatelessWidget {
  const IndexPillButton({
    required this.label,
    required this.onPressed,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  /// Stretch to the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.primary,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 40,
            width: expand ? double.infinity : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionRegular.copyWith(
                    color: AppColors.cream400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
