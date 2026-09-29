import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';

enum RoomStatus { live, ended }

/// Pill badge for room status ("● مباشر" / "انتهت").
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final RoomStatus status;

  @override
  Widget build(BuildContext context) {
    final isLive = status == RoomStatus.live;
    final foreground = isLive
        ? AppColors.liveForeground
        : AppColors.textSecondary;

    return Container(
      height: 32,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isLive ? AppColors.liveBackground : AppColors.endedBackground,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.liveDot,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 8),
            ),
            const SizedBox(width: AppSpacing.xxs + 2),
          ],
          Text(
            isLive ? 'مباشر' : 'انتهت',
            style: AppTypography.labelBold.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
