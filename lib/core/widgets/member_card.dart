import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';

/// Figma "Member Card": member name and handle on a cream tile.
class MemberCard extends StatelessWidget {
  const MemberCard({
    required this.name,
    required this.username,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String name;
  final String username;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: AppRadius.mdAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      username,
                      textDirection: TextDirection.ltr,
                      style: AppTypography.smallRegular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
