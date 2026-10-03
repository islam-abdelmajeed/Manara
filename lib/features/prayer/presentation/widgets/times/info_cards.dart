import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/prayer/domain/entities/prayer_method.dart';
import 'package:manara/features/prayer/domain/entities/qibla.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';

/// Six facts under today's times: method, time zone, coordinates, day
/// length, distance to the Kaaba and qibla bearing.
class InfoCards extends StatelessWidget {
  const InfoCards({super.key});

  static const Size cardSize = Size(202, 127);
  static const double gap = 25;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PrayerTimesCubit>().state;
    final location = state.location;
    final qibla = Qibla.from(location.latitude, location.longitude);
    final dayLength = state.times?.today.dayLength;
    final method = PrayerMethod.byId(state.settings.method);

    final items = [
      ('طريقة الحساب', method?.label ?? '—'),
      ('المنطقة الزمنية', location.timeZone),
      (
        'الإحداثيات',
        PrayerFormat.coordinates(location.latitude, location.longitude),
      ),
      (
        'طول النهار',
        dayLength == null ? '—' : PrayerFormat.duration(dayLength),
      ),
      ('المسافة إلى الكعبة', PrayerFormat.km(qibla.distanceKm)),
      (
        'اتجاه القبلة',
        '${PrayerFormat.degrees(qibla.bearing)} ${qibla.directionLabel}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1200
            ? 6
            : width >= 600
            ? 3
            : 2;
        final gap = width < 600 ? AppSpacing.sm : InfoCards.gap;
        // Never negative: Android's first frame has width 0.
        final share = math.max(0.0, (width - gap * (columns - 1)) / columns);
        // One row keeps the design width; fewer columns fill the width.
        final cardWidth = columns == 6
            ? math.min(cardSize.width, share)
            : share;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, value) in items)
              SizedBox(
                width: cardWidth,
                child: _InfoCard(label: label, value: value),
              ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Room for a two-line value, so cards in a row match.
          minHeight: PrayerLayout.isCompact(context)
              ? 116
              : InfoCards.cardSize.height,
        ),
        child: PrayerPanel(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                value,
                // Coordinates and zones read left to right.
                textDirection: value.contains(RegExp('[ء-ي]'))
                    ? null
                    : TextDirection.ltr,
                style: AppTypography.bodyLargeRegular.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
