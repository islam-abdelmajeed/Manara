import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_times.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';

/// Prayer times card. At design width the Figma artwork (panels and mosque)
/// is the background and the content sits on its panels; on narrow screens
/// the panels are drawn in code and the mosque is left out.
class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({this.clock = DateTime.now, super.key});

  /// Injectable for tests.
  final DateTime Function() clock;

  static const Size designSize = Size(628, 347);

  /// Narrower than this, the design layout gets too small to read.
  static const double minDesignWidth = 470;

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  Timer? _ticker;
  late DateTime _now = widget.clock();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = widget.clock());
      // The cubit reloads at the location's midnight; this catches a timer
      // that was held up while the app was in the background.
      final times = context.read<PrayerTimesCubit>().state.times;
      if (times != null && !_now.isBefore(times.tomorrow.start)) {
        unawaited(context.read<PrayerTimesCubit>().refreshIfStale());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PrayerTimesCubit>().state;
    final data = _PrayerData(state: state, now: _now);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= PrayerTimesCard.minDesignWidth) {
          return DesignBox(
            size: PrayerTimesCard.designSize,
            child: _DesignLayout(data: data),
          );
        }
        return _CompactLayout(data: data);
      },
    );
  }
}

/// What the card shows, derived from the cubit state and the current time.
class _PrayerData {
  _PrayerData({required this.state, required this.now});

  final PrayerTimesState state;
  final DateTime now;

  PrayerTimes? get times => state.times;

  String get locationLabel => state.location.label;

  NextPrayer? get next => times?.nextPrayer(now);

  bool get failed => state.status == PrayerTimesStatus.failure && times == null;

  String timeOf(Prayer prayer) {
    final t = times;
    return t == null ? '--:--' : formatClock(t.timeOf(prayer).local);
  }

  String get countdown {
    final n = next;
    if (n == null) return '-- : -- : --';
    final left = n.time.instant.difference(now);
    final safe = left.isNegative ? Duration.zero : left;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(safe.inHours)} : ${two(safe.inMinutes % 60)} : '
        '${two(safe.inSeconds % 60)}';
  }

  String get nextTime {
    final n = next;
    if (n == null) return '--:--';
    final local = n.time.local;
    return '${formatClock(local)} ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  /// 12-hour `hh:mm` of a location wall-clock time, as in the design.
  static String formatClock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
}

abstract final class _Style {
  static const border = Color(0xFFE2BC86);
  static const accent = AppColors.lightGold500;
  static const radius = BorderRadius.all(Radius.circular(19));
  static const shadow = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 20),
  ];

  static final label = AppTypography.captionMedium.copyWith(
    color: Colors.black,
  );
  static final rowText = AppTypography.captionBold.copyWith(
    color: Colors.black,
  );
  static final nextName = AppTypography.h4Bold.copyWith(color: Colors.black);
  static const countdown = TextStyle(
    fontFamily: AppTypography.counterFontFamily,
    fontSize: 26,
    height: 36 / 26,
    color: accent,
  );
  static final nextTime = AppTypography.bodyLargeMedium.copyWith(
    color: Colors.black,
  );
  static final pill = AppTypography.bodyMedium.copyWith(
    color: AppColors.primary,
  );
}

class _DesignLayout extends StatelessWidget {
  const _DesignLayout({required this.data});

  final _PrayerData data;

  @override
  Widget build(BuildContext context) {
    // Positions are from Figma (frame "Frame 69"); the artwork is 4px taller
    // than the frame, so every frame y is shifted by 4.
    return Container(
      decoration: const BoxDecoration(
        borderRadius: _Style.radius,
        boxShadow: _Style.shadow,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: _Style.radius,
        border: Border.all(
          color: _Style.border,
          width: 3,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: _Style.radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppImages.cardPrayer,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              left: 224,
              top: 43,
              width: 173,
              child: _TimesList(data: data),
            ),
            Positioned(
              left: 44,
              top: 83,
              width: 128,
              child: _NextPrayer(data: data),
            ),
            Positioned(
              left: 217,
              top: 284,
              width: 185,
              height: 35,
              child: _Pill(
                icon: AppIcons.markerPin,
                label: data.locationLabel,
                onTap: () => context.go(AppRoutes.prayerSettings),
              ),
            ),
            Positioned(
              left: 19,
              top: 284,
              width: 182,
              height: 35,
              child: _HijriPill(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.data});

  final _PrayerData data;

  static const _panel = BoxDecoration(
    color: Color(0xFFFBF4EE),
    borderRadius: AppRadius.mdAll,
    border: Border.fromBorderSide(BorderSide(color: Color(0xFFF0DFCF))),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF3EE), Color(0xFFFCF4EF)],
        ),
        borderRadius: _Style.radius,
        border: Border.all(color: _Style.border, width: 3),
        boxShadow: _Style.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: _panel,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: _TimesList(data: data),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DecoratedBox(
                    decoration: _panel,
                    child: Center(child: _NextPrayer(data: data)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: _panel,
                  child: SizedBox(
                    height: 40,
                    child: _Pill(
                      icon: AppIcons.markerPin,
                      label: data.locationLabel,
                      onTap: () => context.go(AppRoutes.prayerSettings),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DecoratedBox(
                  decoration: _panel,
                  child: SizedBox(height: 40, child: _HijriPill(data: data)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Six rows (Fajr to Isha); the next prayer is highlighted.
class _TimesList extends StatelessWidget {
  const _TimesList({required this.data});

  final _PrayerData data;

  @override
  Widget build(BuildContext context) {
    final next = data.next?.prayer;
    return Column(
      children: [
        for (final prayer in Prayer.values)
          SizedBox(
            height: 34,
            child: Center(
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: prayer == next
                    ? const BoxDecoration(
                        color: AppColors.lightGold200,
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      )
                    : null,
                child: Row(
                  children: [
                    Text(prayer.label, style: _Style.rowText),
                    const Spacer(),
                    Text(
                      data.timeOf(prayer),
                      textDirection: TextDirection.ltr,
                      style: _Style.rowText,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NextPrayer extends StatelessWidget {
  const _NextPrayer({required this.data});

  final _PrayerData data;

  @override
  Widget build(BuildContext context) {
    if (data.failed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تعذّر تحميل المواقيت',
              textAlign: TextAlign.center,
              style: _Style.label,
            ),
            TextButton(
              onPressed: () => context.read<PrayerTimesCubit>().load(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('الصلاة القادمة', style: _Style.label),
        const SizedBox(height: 11),
        Text(data.next?.prayer.label ?? '--', style: _Style.nextName),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            data.countdown,
            textDirection: TextDirection.ltr,
            style: _Style.countdown,
          ),
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppIcons.sun, size: 30, color: _Style.accent),
            const SizedBox(width: 18),
            Text(
              data.nextTime,
              textDirection: TextDirection.ltr,
              style: _Style.nextTime,
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 25, color: _Style.accent),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _Style.pill,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HijriPill extends StatelessWidget {
  const _HijriPill({required this.data});

  final _PrayerData data;

  @override
  Widget build(BuildContext context) {
    final hijri = data.times?.hijriDate;
    return Semantics(
      label: hijri == null ? null : 'التقويم الهجري، اليوم $hijri',
      child: _Pill(
        icon: AppIcons.calendar,
        label: 'التقويم الهجري',
        onTap: () => context.go(AppRoutes.prayerMonthly),
      ),
    );
  }
}
