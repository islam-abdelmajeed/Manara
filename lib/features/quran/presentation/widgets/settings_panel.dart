import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:manara/features/quran/presentation/utils/reader_palette.dart';
import 'package:manara/features/quran/presentation/widgets/panel_header.dart';

/// Reader preferences: font, size, spacing, colors and display toggles.
/// Every change is applied to the page immediately and persisted.
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReaderSettingsCubit>().state;
    final cubit = context.read<ReaderSettingsCubit>();

    return Column(
      children: [
        PanelHeader(title: 'الإعدادات', onClose: onClose),
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            children: [
              _Section(
                title: 'خط المصحف',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final font in MushafFont.values)
                      _OptionChip(
                        label: _fontLabel(font),
                        selected: settings.font == font,
                        onTap: () => cubit.setFont(font),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'حجم الخط',
                child: Row(
                  children: [
                    Text('صغير', style: AppTypography.labelBold),
                    Expanded(
                      child: Slider(
                        value: settings.fontScale,
                        min: ReaderSettings.minFontScale,
                        max: ReaderSettings.maxFontScale,
                        divisions: 8,
                        semanticFormatterCallback: (v) =>
                            'حجم الخط ${(v * 100).round()}%',
                        onChanged: cubit.setFontScale,
                      ),
                    ),
                    Text('كبير', style: AppTypography.bodyBold),
                  ],
                ),
              ),
              _Section(
                title: 'تباعد الأسطر',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final spacing in LineSpacing.values)
                      _TextOption(
                        label: _spacingLabel(spacing),
                        selected: settings.lineSpacing == spacing,
                        onTap: () => cubit.setLineSpacing(spacing),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'لون الخط',
                child: _ColorRow(
                  colors: ReaderPalette.textColors,
                  selectedIndex: settings.textColorIndex,
                  onSelected: cubit.setTextColor,
                ),
              ),
              _Section(
                title: 'لون الخلفية',
                child: _ColorRow(
                  colors: ReaderPalette.backgroundColors,
                  selectedIndex: settings.backgroundColorIndex,
                  onSelected: cubit.setBackgroundColor,
                ),
              ),
              _Section(
                showDivider: false,
                child: Column(
                  children: [
                    _CheckRow(
                      label: 'إظهار علامات الوقف',
                      value: settings.showStopMarks,
                      onChanged: cubit.setShowStopMarks,
                    ),
                    _CheckRow(
                      label: 'إظهار التشكيل',
                      value: settings.showTashkeel,
                      onChanged: cubit.setShowTashkeel,
                    ),
                    _CheckRow(
                      label: 'تظليل الآية أثناء التلاوة',
                      value: settings.highlightWhilePlaying,
                      onChanged: cubit.setHighlightWhilePlaying,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _fontLabel(MushafFont font) => switch (font) {
    MushafFont.amiri => 'الخط الأميري',
  };

  static String _spacingLabel(LineSpacing spacing) => switch (spacing) {
    LineSpacing.normal => 'عادي',
    LineSpacing.medium => 'متوسط',
    LineSpacing.large => 'كبير',
  };
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.title, this.showDivider = true});

  final String? title;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.h5Medium.copyWith(color: Colors.black),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          child,
          if (showDivider) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.primary, thickness: 2, height: 2),
          ],
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.surfaceSelected : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: selected ? AppColors.primary : Colors.black,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 131, minHeight: 44),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: Text(label, style: AppTypography.captionMedium),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextOption extends StatelessWidget {
  const _TextOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style:
                  (selected
                          ? AppTypography.bodyLargeBold
                          : AppTypography.bodyLargeRegular)
                      .copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.colors,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<Color> colors;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < colors.length; i++)
          Semantics(
            button: true,
            selected: i == selectedIndex,
            label: 'لون ${i + 1}',
            child: InkResponse(
              onTap: () => onSelected(i),
              radius: 26,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == selectedIndex
                        ? AppColors.primary
                        : Colors.black,
                    width: i == selectedIndex ? 3 : 1,
                  ),
                ),
                child: i == selectedIndex
                    ? Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: colors[i].computeLuminance() > 0.5
                            ? AppColors.primary
                            : Colors.white,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? value),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
      title: Text(
        label,
        style: AppTypography.h5Medium.copyWith(
          fontSize: 18,
          color: Colors.black,
        ),
      ),
    );
  }
}
