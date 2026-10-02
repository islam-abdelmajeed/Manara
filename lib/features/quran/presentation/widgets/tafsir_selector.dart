import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';

/// "المختصر ⌄" in the reader header; opens the list of tafsir books
/// (Figma "Frame 245": white panel, a "نوع التفسير" title row, a check on
/// every option that is dark only for the selected one).
class TafsirSelector extends StatefulWidget {
  const TafsirSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final TafsirSource selected;
  final ValueChanged<TafsirSource> onSelected;

  @override
  State<TafsirSelector> createState() => _TafsirSelectorState();
}

class _TafsirSelectorState extends State<TafsirSelector> {
  final _controller = MenuController();

  static const double _menuWidth = 170;
  static const TextStyle _itemStyle = AppTypography.bodyRegular;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: WidgetStatePropertyAll(AppColors.surface),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: WidgetStatePropertyAll(4),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      menuChildren: [
        _MenuRow(
          label: 'نوع التفسير',
          icon: const Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 22,
            color: AppColors.textPrimary,
          ),
          onTap: _controller.close,
        ),
        for (final source in TafsirSource.values)
          _MenuRow(
            label: source.label,
            selected: source == widget.selected,
            icon: Icon(
              Icons.check_rounded,
              size: 20,
              color: source == widget.selected
                  ? AppColors.textPrimary
                  : AppColors.border,
            ),
            onTap: () {
              _controller.close();
              if (source != widget.selected) widget.onSelected(source);
            },
          ),
      ],
      builder: (context, controller, _) {
        return Semantics(
          button: true,
          label: 'نوع التفسير',
          child: InkWell(
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            borderRadius: AppRadius.smAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.xxs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.selected.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _itemStyle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _TafsirSelectorState._menuWidth,
          height: 44,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: _TafsirSelectorState._itemStyle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                icon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
