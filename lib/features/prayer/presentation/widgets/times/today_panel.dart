import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';

/// Today's six times and the countdown to the next prayer. At design width
/// the Figma arrangement (list, countdown, illustration) is kept and scaled;
/// on phones the countdown sits above the list.
class TodayPanel extends StatelessWidget {
  const TodayPanel({required this.now, super.key});

  final DateTime now;

  /// Figma: list 450 wide, countdown column, mosque illustration.
  static const Size designSize = Size(PrayerLayout.contentWidth, 452);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PrayerTimesCubit>().state;
    final times = state.times;
    final next = times?.nextPrayer(now);

    if (times == null && state.status == PrayerTimesStatus.failure) {
      return _LoadError(message: state.errorMessage);
    }

    if (PrayerLayout.isCompact(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrayerPanel(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: _NextPrayer(next: next, now: now, compact: true),
          ),
          const SizedBox(height: AppSpacing.md),
          _TimesList(times: times, next: next?.prayer, compact: true),
        ],
      );
    }

    return DesignBox(
      size: designSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 8,
            width: 450,
            child: _TimesList(times: times, next: next?.prayer),
          ),
          Positioned(
            left: 500,
            top: 70,
            width: 284,
            child: _NextPrayer(next: next, now: now),
          ),
          // Figma node 2124:2457: 593 × 465, 16 above the first row. Its
          // transparent top and ground shadow reach a few pixels past the
          // box, hence Clip.none.
          Positioned(
            left: 769,
            top: -8,
            width: 593,
            height: 465,
            child: Image.asset(
              AppImages.prayerMosque,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimesList extends StatelessWidget {
  const _TimesList({
    required this.times,
    required this.next,
    this.compact = false,
  });

  final PrayerTimes? times;
  final Prayer? next;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rowHeight = compact ? 52.0 : 66.0;
    final gap = compact ? 6.0 : 7.0;
    final nameStyle =
        (compact ? AppTypography.bodyLargeMedium : AppTypography.subtitleMedium)
            .copyWith(color: AppColors.textPrimary);
    final timeStyle =
        (compact ? AppTypography.bodyMedium : AppTypography.bodyLargeMedium)
            .copyWith(color: AppColors.textPrimary);

    return Column(
      children: [
        for (final prayer in Prayer.values) ...[
          if (prayer != Prayer.fajr) SizedBox(height: gap),
          Semantics(
            label: [
              prayer.label,
              if (times case final t?)
                PrayerFormat.clockWithPeriod(t.timeOf(prayer)),
              if (prayer == next) 'الصلاة القادمة',
            ].join('، '),
            excludeSemantics: true,
            child: Container(
              height: rowHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: prayer == next ? AppColors.green300 : null,
                borderRadius: AppRadius.mdAll,
                border: prayer == next
                    ? null
                    : Border.all(color: AppColors.green300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(prayer.label, style: nameStyle),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      times == null
                          ? '--:--'
                          : PrayerFormat.clock(times!.timeOf(prayer)),
                      textDirection: TextDirection.ltr,
                      style: timeStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NextPrayer extends StatelessWidget {
  const _NextPrayer({
    required this.next,
    required this.now,
    this.compact = false,
  });

  final NextPrayer? next;
  final DateTime now;
  final bool compact;

  /// Figma draws the name and time at 40 (no text style that size).
  static final TextStyle _big = AppTypography.displayBold.copyWith(
    fontSize: 40,
    height: 46 / 40,
    color: AppColors.primary,
  );

  @override
  Widget build(BuildContext context) {
    final next = this.next;
    final (h, m, s) = PrayerFormat.countdown(
      next == null ? Duration.zero : next.time.instant.difference(now),
    );
    final big = compact ? _big.copyWith(fontSize: 32, height: 38 / 32) : _big;
    final label = next == null
        ? 'الصلاة القادمة'
        : 'الصلاة القادمة ${next.prayer.label} '
              'الساعة ${PrayerFormat.clockWithPeriod(next.time)}، '
              'المتبقي $h ساعة و$m دقيقة';

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الصلاة القادمة',
              style:
                  (compact ? AppTypography.h4Regular : AppTypography.h1Regular)
                      .copyWith(color: AppColors.primary),
            ),
            SizedBox(height: compact ? AppSpacing.sm : 40),
            Text(next?.prayer.label ?? '--', style: big),
            Text(
              next == null ? '--:--' : PrayerFormat.clockWithPeriod(next.time),
              style: big,
            ),
            SizedBox(height: compact ? AppSpacing.sm : 30),
            Text(
              'المتبقّي',
              style:
                  (compact
                          ? AppTypography.bodyLargeMedium
                          : AppTypography.h5Medium)
                      .copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: compact ? AppSpacing.xs : 18),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, part) in [h, m, s].indexed) ...[
                    if (i > 0) const SizedBox(width: 14),
                    _CountBox(part),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBox extends StatelessWidget {
  const _CountBox(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.green800, width: 1.5),
      ),
      child: Text(
        value,
        style: AppTypography.h5Bold.copyWith(color: AppColors.green800),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return PrayerPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'تعذّر تحميل المواقيت',
            textAlign: TextAlign.center,
            style: AppTypography.subtitleBold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (message case final m?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              m,
              textAlign: TextAlign.center,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'إعادة المحاولة',
            onPressed: () => context.read<PrayerTimesCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
