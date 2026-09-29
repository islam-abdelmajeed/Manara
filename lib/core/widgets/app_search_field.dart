import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_icon.dart';

/// Pill-shaped search box from the surah picker screen (44 high, radius 24).
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.fillColor,
    this.iconAtEnd = false,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Background; transparent when `null`.
  final Color? fillColor;

  /// Puts the search icon after the text (left in RTL) instead of before it.
  final bool iconAtEnd;

  static const double _height = 44;

  static const _border = OutlineInputBorder(
    borderRadius: AppRadius.xlAll,
    borderSide: BorderSide(color: AppColors.borderStrong),
  );

  Widget get _icon => Padding(
    padding: EdgeInsetsDirectional.only(
      start: iconAtEnd ? AppSpacing.xs : AppSpacing.sm,
      end: iconAtEnd ? AppSpacing.md : AppSpacing.xs,
    ),
    child: const AppIcon(
      AppIcons.search,
      size: 20,
      color: AppColors.darkBrown900,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _height),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        style: AppTypography.captionRegular.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.labelRegular.copyWith(
            color: AppColors.textHint,
          ),
          filled: fillColor != null,
          fillColor: fillColor,
          isDense: true,
          // The border hugs the content, so the height is made of the text
          // line plus this padding.
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          prefixIcon: iconAtEnd ? null : _icon,
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: iconAtEnd ? _icon : null,
          suffixIconConstraints: const BoxConstraints(),
          border: _border,
          enabledBorder: _border,
          focusedBorder: _border.copyWith(
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
