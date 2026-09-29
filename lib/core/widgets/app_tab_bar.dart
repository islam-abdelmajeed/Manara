import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';

class AppTabItem {
  const AppTabItem({required this.label, this.enabled = true});

  final String label;
  final bool enabled;
}

/// Pill tabs from the reader screens (قراءة / تفسير / ترجمة / ترتيل).
///
/// Selected: dark fill, light text and shadow, 50 high. Unselected: outlined,
/// 40 high. Items are laid out in the reading direction.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<AppTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // Narrow screens use smaller tabs so four of them fit on one row.
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: compact ? AppSpacing.xs : AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < items.length; i++)
          _Tab(
            item: items[i],
            selected: i == selectedIndex,
            compact: compact,
            onTap: items[i].enabled ? () => onChanged(i) : null,
          ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final AppTabItem item;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = selected
        ? (compact
                  ? AppTypography.bodyLargeMedium
                  : AppTypography.subtitleMedium)
              .copyWith(color: AppColors.cream500)
        : (compact ? AppTypography.captionMedium : AppTypography.bodyMedium)
              .copyWith(color: AppColors.tabSelected);

    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: BoxConstraints(
          minHeight: selected ? 50 : 40,
          minWidth: compact ? (selected ? 84 : 64) : (selected ? 110 : 80),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.tabSelected : AppColors.readerBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.readerBackground
                : AppColors.tabSelected,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.tab : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: compact ? AppSpacing.sm : AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  item.label,
                  style: item.enabled
                      ? style
                      : style.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
