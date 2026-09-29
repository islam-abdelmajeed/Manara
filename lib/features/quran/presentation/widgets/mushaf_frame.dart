import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';

/// The green bordered card that holds the Mushaf page or a side panel
/// (Figma: 4px `#425841` stroke, radius 12).
class MushafFrame extends StatelessWidget {
  const MushafFrame({required this.child, this.color, super.key});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.readerBackground,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.primary, width: 4),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md - 2)),
        child: child,
      ),
    );
  }
}
