import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';

/// Top of every prayer screen: the city and today's date (Gregorian and
/// Hijri), then the section tabs.
class PrayerHeader extends StatelessWidget {
  const PrayerHeader({required this.tab, super.key});

  final PrayerTab tab;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PrayerTimesCubit>().state;
    final today = state.times?.today;
    final compact = PrayerLayout.isCompact(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            label: 'المدينة: ${state.location.name}',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(
                  AppIcons.markerPin,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    state.location.name,
                    style: AppTypography.subtitleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          today == null ? ' ' : PrayerFormat.fullDate(today.date, today.hijri),
          style: AppTypography.captionMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: compact ? AppSpacing.lg : 52),
        _Tabs(selected: tab),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected});

  final PrayerTab selected;

  @override
  Widget build(BuildContext context) {
    final compact = PrayerLayout.isCompact(context);
    final tabs = [
      for (final tab in PrayerTab.values)
        _TabPill(
          tab: tab,
          selected: tab == selected,
          onTap: tab == selected ? null : () => context.go(tab.route),
        ),
    ];
    if (!compact) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 37,
        runSpacing: AppSpacing.sm,
        children: tabs,
      );
    }
    // One scrolling row on phones.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            tabs[i],
          ],
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.tab, required this.selected, this.onTap});

  final PrayerTab tab;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = PrayerLayout.isCompact(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.beige500 : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: selected ? AppColors.green600 : AppColors.darkBrown300,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.sm : AppSpacing.md,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  tab.label,
                  style:
                      (compact
                              ? AppTypography.captionMedium
                              : AppTypography.bodyLargeRegular)
                          .copyWith(
                            color: selected
                                ? AppColors.green700
                                : AppColors.darkBrown400,
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
