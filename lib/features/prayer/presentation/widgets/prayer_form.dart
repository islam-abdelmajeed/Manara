import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';

/// Outlined card of the settings and alerts screens: a title, a line of
/// explanation and its controls in a narrower column, as in Figma.
class PrayerFormCard extends StatelessWidget {
  const PrayerFormCard({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Figma: cards 1195 wide, controls in a 910 column.
  static const double width = 1195;
  static const double innerWidth = 910;

  @override
  Widget build(BuildContext context) {
    final compact = PrayerLayout.isCompact(context);
    final subtitle = this.subtitle;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: width),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.green400),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.md : AppSpacing.xl,
              vertical: compact ? AppSpacing.md : 30,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: innerWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: AppTypography.subtitleBold.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: AppTypography.captionRegular.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled field showing the chosen option; tapping it opens the list
/// of options (a sheet on phones, a dialog elsewhere).
class PrayerSelectField<T> extends StatelessWidget {
  const PrayerSelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
    this.optionDetail,
    this.enabled = true,
    super.key,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) optionLabel;
  final String Function(T)? optionDetail;
  final ValueChanged<T> onChanged;
  final bool enabled;

  Future<void> _choose(BuildContext context) async {
    Widget list(BuildContext context) => RadioGroup<T>(
      groupValue: value,
      onChanged: (v) => Navigator.of(context).pop(v),
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final option in options)
            RadioListTile<T>(
              value: option,
              title: Text(
                optionLabel(option),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: optionDetail == null
                  ? null
                  : Text(
                      optionDetail!(option),
                      style: AppTypography.labelRegular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
        ],
      ),
    );

    final T? chosen;
    if (PrayerLayout.isCompact(context)) {
      chosen = await showModalBottomSheet<T>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: list(context),
          ),
        ),
      );
    } else {
      chosen = await showDialog<T>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppColors.background,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    label,
                    style: AppTypography.subtitleBold.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Flexible(child: list(context)),
              ],
            ),
          ),
        ),
      );
    }
    if (chosen != null && chosen != value) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label: ${optionLabel(value)}',
      excludeSemantics: true,
      child: Material(
        color: enabled ? AppColors.readerBackground : AppColors.beige200,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: enabled ? AppColors.green600 : AppColors.beige500,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => _choose(context) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTypography.captionBold.copyWith(
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                        Text(
                          optionLabel(value),
                          style: AppTypography.labelRegular.copyWith(
                            color: enabled
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A − value + stepper. Changes show at once and are reported once the
/// user pauses, so tapping several times makes one change.
class PrayerStepper extends StatefulWidget {
  const PrayerStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onChanged,
    this.delay = const Duration(milliseconds: 600),
    super.key,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String Function(int) valueLabel;
  final ValueChanged<int> onChanged;
  final Duration delay;

  @override
  State<PrayerStepper> createState() => _PrayerStepperState();
}

class _PrayerStepperState extends State<PrayerStepper> {
  late int _value = widget.value;
  Timer? _commit;

  @override
  void didUpdateWidget(PrayerStepper old) {
    super.didUpdateWidget(old);
    // Follow outside changes (e.g. restoring defaults) unless mid-edit.
    if (_commit == null && widget.value != _value) _value = widget.value;
  }

  void _set(int value) {
    setState(() => _value = value.clamp(widget.min, widget.max));
    _commit?.cancel();
    _commit = Timer(widget.delay, () {
      _commit = null;
      if (_value != widget.value) widget.onChanged(_value);
    });
  }

  @override
  void dispose() {
    // Don't lose a change made just before leaving.
    if (_commit != null && _value != widget.value) widget.onChanged(_value);
    _commit?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.valueLabel(_value);
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: 'إنقاص ${widget.label}',
          onPressed: _value > widget.min ? () => _set(_value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
          color: AppColors.primary,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72),
          child: Semantics(
            liveRegion: true,
            label: '${widget.label}: $text',
            excludeSemantics: true,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.bodyBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'زيادة ${widget.label}',
          onPressed: _value < widget.max ? () => _set(_value + 1) : null,
          icon: const Icon(Icons.add_rounded),
          color: AppColors.primary,
        ),
      ],
    );
  }
}
