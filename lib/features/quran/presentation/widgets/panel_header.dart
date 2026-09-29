import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_icon.dart';

/// Title bar shared by the navigation and settings panels: a close button
/// and a title, with the Figma header shadow.
class PanelHeader extends StatelessWidget {
  const PanelHeader({required this.title, required this.onClose, super.key});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 67),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.readerBackground,
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.mushafHeader,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.subtitleBold.copyWith(
                color: AppColors.green900,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'إغلاق',
            icon: const AppIcon(
              AppIcons.exit,
              size: 26,
              color: AppColors.green900,
            ),
          ),
        ],
      ),
    );
  }
}
