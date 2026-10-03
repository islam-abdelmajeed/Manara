import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/prayer/domain/entities/prayer_location.dart';
import 'package:manara/features/prayer/domain/entities/qibla.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/utils/prayer_format.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';
import 'package:manara/features/prayer/presentation/widgets/use_my_location_button.dart';

/// "اتجاه القبلة": the bearing to the Kaaba on a dial with north up, and
/// the distance. Calculated on the device, so it works offline.
class QiblaSection extends StatelessWidget {
  const QiblaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final location = context.select<PrayerTimesCubit, PrayerLocation>(
      (c) => c.state.location,
    );
    final qibla = Qibla.from(location.latitude, location.longitude);
    final compact = PrayerLayout.isCompact(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrayerSectionTitle(
          'اتجاه القبلة – كيف تجد اتجاه الكعبة',
          large: false,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'اتجاه الدائرة العظمى الدقيق من موقعك إلى الكعبة المشرّفة، '
          'مقيسًا من الشمال الجغرافي باتجاه عقارب الساعة.',
          style:
              (compact
                      ? AppTypography.captionRegular
                      : AppTypography.bodyLargeRegular)
                  .copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: compact ? AppSpacing.xl : 109),
        Center(
          child: QiblaDial(qibla: qibla, size: compact ? 240 : 319),
        ),
        const SizedBox(height: 35),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 9,
          runSpacing: AppSpacing.xs,
          children: [
            // Reading order as in Figma: "use my location" first.
            const UseMyLocationButton(),
            AppButton(
              label: 'ابدأ البوصلة الحية',
              icon: AppIcons.compass,
              onPressed: () => showComingSoon(context),
            ),
          ],
        ),
        const SizedBox(height: 27),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 736),
            child: _QiblaTable(location: location, qibla: qibla),
          ),
        ),
      ],
    );
  }
}

class _QiblaTable extends StatelessWidget {
  const _QiblaTable({required this.location, required this.qibla});

  final PrayerLocation location;
  final Qibla qibla;

  @override
  Widget build(BuildContext context) {
    final cells = [
      ('اتجاه القبلة', PrayerFormat.degrees(qibla.bearing)),
      ('المسافة إلى الكعبة', PrayerFormat.km(qibla.distanceKm)),
      (
        'الإحداثيات',
        PrayerFormat.coordinates(location.latitude, location.longitude),
      ),
    ];
    const border = BorderSide(color: AppColors.green100);
    Widget cell((String, String) item) {
      final (label, value) = item;
      return Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    );
    // Phones stack the three facts; wider screens put them in a row.
    if (PrayerLayout.isCompact(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.green100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in cells.indexed)
              Container(
                decoration: BoxDecoration(
                  border: i == 0 ? null : const Border(top: border),
                ),
                padding: padding,
                child: cell(item),
              ),
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: AppColors.green100)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in cells.indexed)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const BorderDirectional(start: border),
                  ),
                  padding: padding,
                  child: cell(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compass dial with north up and the qibla marked at its bearing.
class QiblaDial extends StatelessWidget {
  const QiblaDial({required this.qibla, this.size = 319, super.key});

  final Qibla qibla;
  final double size;

  @override
  Widget build(BuildContext context) {
    final degrees = PrayerFormat.degrees(qibla.bearing);
    return Semantics(
      label:
          'اتجاه القبلة $degrees من الشمال باتجاه عقارب الساعة '
          '(${qibla.directionLabel})',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _DialPainter(bearing: qibla.bearing),
          child: Center(
            child: Container(
              width: size * 0.38,
              height: size * 0.38,
              decoration: BoxDecoration(
                color: AppColors.white50,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.green100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        degrees,
                        textDirection: TextDirection.ltr,
                        style: AppTypography.h3Regular.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        qibla.directionLabel,
                        style: AppTypography.captionRegular.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

class _DialPainter extends CustomPainter {
  const _DialPainter({required this.bearing});

  /// Degrees clockwise from north.
  final double bearing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0x1A000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawCircle(center, radius, Paint()..color = AppColors.white50)
      ..drawCircle(
        center,
        radius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.green100,
      );

    // Angle in screen terms: 0° (north) points up.
    Offset at(double degrees, double r) {
      final a = (degrees - 90) * math.pi / 180;
      return center + Offset(math.cos(a), math.sin(a)) * r;
    }

    final tick = Paint()..strokeCap = StrokeCap.round;
    for (var d = 0; d < 360; d += 5) {
      final major = d % 90 == 0;
      final mid = d % 45 == 0;
      final length = radius * (major ? 0.09 : (mid ? 0.07 : 0.035));
      tick
        ..color = major ? AppColors.darkBrown400 : AppColors.darkBrown200
        ..strokeWidth = major ? 2 : 1;
      canvas.drawLine(
        at(d.toDouble(), radius * 0.92),
        at(d.toDouble(), radius * 0.92 - length),
        tick,
      );
    }

    // Cardinal letters, as in the Figma dial.
    for (final (label, d) in const [
      ('N', 0),
      ('E', 90),
      ('S', 180),
      ('W', 270),
    ]) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: AppTypography.captionBold.copyWith(
            color: AppColors.darkBrown400,
            fontSize: radius * 0.08,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        at(d.toDouble(), radius * 0.70) -
            Offset(painter.width / 2, painter.height / 2),
      );
      painter.dispose();
    }

    // The qibla: a gold needle from the centre box to a ring marker.
    final gold = Paint()
      ..color = AppColors.lightGold500
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      at(bearing, radius * 0.30),
      at(bearing, radius * 0.74),
      gold,
    );
    final marker = at(bearing, radius * 0.80);
    canvas
      ..drawCircle(marker, radius * 0.07, Paint()..color = AppColors.white50)
      ..drawCircle(
        marker,
        radius * 0.07,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.lightGold500,
      )
      ..drawCircle(
        marker,
        radius * 0.03,
        Paint()..color = AppColors.lightGold500,
      );
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.bearing != bearing;
}
