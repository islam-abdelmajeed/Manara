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
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static const _border = OutlineInputBorder(
    borderRadius: AppRadius.xlAll,
    borderSide: BorderSide(color: AppColors.borderStrong),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
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
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              end: AppSpacing.xs,
            ),
            child: AppIcon(
              AppIcons.search,
              size: 20,
              color: AppColors.darkBrown900,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
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
