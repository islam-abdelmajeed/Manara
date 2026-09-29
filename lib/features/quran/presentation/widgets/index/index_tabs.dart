import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/quran/presentation/cubit/quran_index_cubit.dart';
import 'package:manara/features/quran/presentation/widgets/index/index_style.dart';

/// Tab chips above the grid ("السور", "الأجزاء", …), 44 high, 30 apart.
/// [compact] tightens them for phones; they scroll sideways if they still
/// don't fit.
class IndexTabs extends StatelessWidget {
  const IndexTabs({
    required this.selected,
    required this.onSelected,
    this.compact = false,
    super.key,
  });

  final QuranIndexTab selected;
  final ValueChanged<QuranIndexTab> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in QuranIndexTab.values) ...[
            if (tab != QuranIndexTab.values.first)
              SizedBox(width: compact ? AppSpacing.xs : 30),
            _TabChip(
              label: tab.label,
              selected: tab == selected,
              padding: compact ? 14 : AppSpacing.lg,
              onTap: () => onSelected(tab),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.padding,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double padding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : IndexStyle.cardColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : IndexStyle.borderColor,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppTypography.bodyRegular.copyWith(
                    color: selected
                        ? AppColors.cream400
                        : IndexStyle.titleColor,
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
