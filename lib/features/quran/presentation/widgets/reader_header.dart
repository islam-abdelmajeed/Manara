import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_icon.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/presentation/utils/quran_labels.dart';

/// Sticky header of the Mushaf card: navigation menu, play button with the
/// surah title, and settings.
class ReaderHeader extends StatelessWidget {
  const ReaderHeader({
    required this.surah,
    required this.onNavigationTap,
    required this.onSettingsTap,
    required this.onPlayTap,
    this.compact = false,
    super.key,
  });

  final Surah? surah;
  final VoidCallback onNavigationTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onPlayTap;

  /// Tighter padding for small screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = surah;

    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.xxxl,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.readerBackground,
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.mushafHeader,
      ),
      child: Row(
        children: [
          _HeaderButton(
            icon: AppIcons.options,
            tooltip: 'الانتقال إلى',
            onTap: onNavigationTap,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeaderButton(
                  icon: AppIcons.play,
                  tooltip: 'استماع',
                  size: 27,
                  onTap: onPlayTap,
                ),
                const SizedBox(width: AppSpacing.xs),
                const SizedBox(
                  height: 25,
                  child: VerticalDivider(width: 1, color: Color(0x45000000)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: _Title(surah: current)),
              ],
            ),
          ),
          _HeaderButton(
            icon: AppIcons.settings,
            tooltip: 'الإعدادات',
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.surah});

  final Surah? surah;

  @override
  Widget build(BuildContext context) {
    final current = surah;
    if (current == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سورة ${current.nameArabic}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          QuranLabels.headerSubtitle(current),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.smallRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 28,
  });

  final String icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: AppIcon(icon, size: size, color: AppColors.textPrimary),
    );
  }
}
