import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/platform/browser_actions.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_method.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_month_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_export.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';

/// "الجدول الشهري" (Figma "الصلاة - الجدول شهري"). Expects
/// [PrayerMonthCubit] above it, which the page keeps on the location's
/// current month until the user moves.
class MonthlyTab extends StatelessWidget {
  const MonthlyTab({required this.clock, super.key});

  final DateTime Function() clock;

  static const String note =
      'تُحسب مواقيت الصلاة فلكيًا. قد تختلف إعلانات المسجد المحلي بدقائق – '
      'اتبع مسجدك المحلي كلما أمكن.';

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerTimesCubit>().state;
    final month = context.watch<PrayerMonthCubit>().state;
    final compact = PrayerLayout.isCompact(context);
    final data = month.data;
    final today = data?.dayAt(clock())?.date;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrayerSectionTitle(
          'جدول مواقيت الصلاة الشهري لمدينة ${prayer.location.name}',
          large: false,
        ),
        SizedBox(height: compact ? AppSpacing.md : 35),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.sm,
          children: [
            _MonthPicker(year: month.year, month: month.month),
            _Actions(data: data, clock: clock),
          ],
        ),
        SizedBox(height: compact ? AppSpacing.md : 18),
        switch (month.status) {
          PrayerMonthStatus.failure => _Error(message: month.errorMessage),
          _ when data == null => const _Loading(),
          _ =>
            compact
                ? _DayCards(month: data, today: today)
                : _Table(
                    month: data,
                    today: today,
                    caption:
                        'جدول مواقيت الصلاة الشهري لمدينة '
                        '${prayer.location.name} – '
                        '${PrayerMethod.byId(prayer.settings.method)?.label ?? ''}',
                  ),
        },
        const SizedBox(height: AppSpacing.md),
        const _Note(),
      ],
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerMonthCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'الشهر السابق',
          onPressed: () => cubit.step(-1),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            month == 0 ? '' : PrayerFormat.monthYear(year, month),
            style: AppTypography.bodyLargeMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: 'الشهر التالي',
          onPressed: () => cubit.step(1),
          icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.data, required this.clock});

  final PrayerMonth? data;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final data = this.data;
    final prayer = context.read<PrayerTimesCubit>().state;
    // Download and print need the browser; elsewhere they are not built yet.
    void exportIcs() {
      if (data == null) return;
      if (!BrowserActions.supported) return showComingSoon(context);
      BrowserActions.download(
        'prayer-times-${prayer.location.nameEn.toLowerCase()}-'
            '${data.year}-${data.month.toString().padLeft(2, '0')}.ics',
        'text/calendar',
        PrayerExport.ics(month: data, location: prayer.location, now: clock()),
      );
    }

    void printTable() {
      if (data == null) return;
      if (!BrowserActions.supported) return showComingSoon(context);
      BrowserActions.printHtml(
        PrayerExport.printableHtml(
          month: data,
          location: prayer.location,
          methodLabel: PrayerMethod.byId(prayer.settings.method)?.label ?? '',
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: AppSpacing.xs,
      children: [
        _ActionChip(
          icon: const AppIcon(
            AppIcons.share,
            size: 16,
            color: AppColors.textPrimary,
          ),
          label: 'مشاركة',
          onTap: () => showComingSoon(context),
        ),
        _ActionChip(
          icon: const AppIcon(
            AppIcons.calendar,
            size: 16,
            color: AppColors.textPrimary,
          ),
          label: 'تصدير iCal',
          onTap: data == null ? null : exportIcs,
        ),
        _ActionChip(
          // No print icon among the app's icons.
          icon: const Icon(
            Icons.print_outlined,
            size: 16,
            color: AppColors.textPrimary,
          ),
          label: 'طباعة',
          onTap: data == null ? null : printTable,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, this.onTap});

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: AppColors.white50,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
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

/// Column widths measured from Figma, start (date) to end (Isha).
const List<double> _columns = [184, 177, 162, 151, 141, 133, 132, 134];

class _Table extends StatelessWidget {
  const _Table({
    required this.month,
    required this.today,
    required this.caption,
  });

  final PrayerMonth month;
  final DateTime? today;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.labelRegular.copyWith(
      color: AppColors.textSecondary,
    );
    final cellStyle = AppTypography.captionRegular.copyWith(
      color: AppColors.textPrimary,
    );

    Widget cell(String text, {bool start = false, TextStyle? style}) => Align(
      alignment: start ? AlignmentDirectional.centerStart : Alignment.center,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: start ? AppSpacing.lg : 0),
        child: Text(text, style: style ?? cellStyle),
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgAll,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(67, 23, 67, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(caption, style: headerStyle),
            const SizedBox(height: 6),
            Table(
              columnWidths: {
                for (final (i, w) in _columns.indexed) i: FlexColumnWidth(w),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.green50),
                  children: [
                    for (final (i, label) in [
                      'التاريخ',
                      'التاريخ الهجري',
                      for (final p in Prayer.values) p.label,
                    ].indexed)
                      SizedBox(
                        height: 44,
                        child: cell(label, start: i == 0, style: headerStyle),
                      ),
                  ],
                ),
                for (final day in month.days)
                  _row(day, cell, cellStyle, isToday: day.date == today),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _row(
    PrayerDay day,
    Widget Function(String, {bool start, TextStyle? style}) cell,
    TextStyle style, {
    required bool isToday,
  }) {
    final friday = day.date.weekday == DateTime.friday;
    return TableRow(
      decoration: BoxDecoration(
        color: isToday ? AppColors.lightGold50 : null,
        border: const Border(top: BorderSide(color: AppColors.beige400)),
      ),
      children: [
        SizedBox(
          height: 50,
          child: Semantics(
            label: [
              '${day.date.day} ${PrayerFormat.weekday(day.date)}',
              if (isToday) 'اليوم',
            ].join('، '),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${day.date.day} ',
                        style: style.copyWith(
                          color: isToday
                              ? AppColors.lightGold600
                              : friday
                              ? AppColors.green500
                              : null,
                        ),
                      ),
                      TextSpan(
                        text: PrayerFormat.weekday(day.date),
                        style: style.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  semanticsLabel: '',
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 50, child: cell(day.hijri.shortLabel)),
        for (final p in Prayer.values)
          SizedBox(
            height: 50,
            child: cell(PrayerFormat.clockWithPeriod(day.timeOf(p))),
          ),
      ],
    );
  }
}

/// Phones: one card per day instead of eight columns.
class _DayCards extends StatelessWidget {
  const _DayCards({required this.month, required this.today});

  final PrayerMonth month;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final day in month.days) ...[
          _DayCard(day: day, isToday: day.date == today),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.isToday});

  final PrayerDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final friday = day.date.weekday == DateTime.friday;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isToday ? AppColors.lightGold50 : AppColors.background,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isToday ? AppColors.lightGold400 : AppColors.beige400,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${day.date.day} ${PrayerFormat.weekday(day.date)}'
                    '${isToday ? ' (اليوم)' : ''}',
                    style: AppTypography.bodyBold.copyWith(
                      color: friday
                          ? AppColors.green500
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  day.hijri.shortLabel,
                  style: AppTypography.captionRegular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            LayoutBuilder(
              builder: (context, constraints) {
                // Three per row; never negative on a zero-width frame.
                final width = (constraints.maxWidth / 3).clamp(
                  0.0,
                  double.infinity,
                );
                return Wrap(
                  runSpacing: AppSpacing.xxs,
                  children: [
                    for (final p in Prayer.values)
                      SizedBox(
                        width: width,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${p.label} ',
                                style: AppTypography.labelRegular.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: PrayerFormat.clockWithPeriod(
                                  day.timeOf(p),
                                ),
                                style: AppTypography.captionMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.lightGold50,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.lightGold200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const AppIcon(
              AppIcons.infoCircle,
              size: 18,
              color: AppColors.lightGold600,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                MonthlyTab.note,
                style: AppTypography.captionRegular.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          semanticsLabel: 'جارٍ تحميل الجدول',
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return PrayerPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'تعذّر تحميل الجدول',
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
            onPressed: () => context.read<PrayerMonthCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
