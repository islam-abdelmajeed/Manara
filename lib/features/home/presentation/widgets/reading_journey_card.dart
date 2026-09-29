import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';

/// "رحلتك في منارة": current juz out of 30 and the reading streak.
class ReadingJourneyCard extends StatelessWidget {
  const ReadingJourneyCard({
    required this.juz,
    required this.streak,
    super.key,
  });

  /// Current juz (0 before any reading).
  final int juz;

  /// Consecutive reading days.
  final int streak;

  static const Size designSize = Size(421, 400);

  /// Arabic wording for the streak line.
  static String streakLabel(int days) {
    if (days <= 0) return 'ابدأ رحلتك اليوم';
    if (days == 1) return 'يوم واحد على التوالي';
    if (days == 2) return 'يومان على التوالي';
    if (days <= 10) return '$days أيام على التوالي';
    return '$days يومًا على التوالي';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'رحلتك في منارة: الجزء $juz من 30، ${streakLabel(streak)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.quranReader),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: DesignBox(
            size: designSize,
            child: Stack(
              children: [
                // Figma casts the shadow from the artwork's rounded frame.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(44)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x40000000),
                          offset: Offset(0, 4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Image.asset(
                    AppImages.cardJourney,
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
                Positioned(
                  left: 94,
                  top: 46,
                  width: 220,
                  child: Column(
                    children: [
                      Text(
                        'رحلتك في منارة',
                        textAlign: TextAlign.center,
                        style: AppTypography.displayRegular.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Progress(juz: juz),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                streakLabel(streak),
                                style: AppTypography.h2Medium.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 7),
                              const AppIcon(
                                AppIcons.starsFilled,
                                size: 35,
                                color: AppColors.lightGold800,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ring with the juz fraction written as "12 / 30" (Figma "Group 7").
class _Progress extends StatelessWidget {
  const _Progress({required this.juz});

  final int juz;

  static const _numberStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 32,
    height: 28 / 32,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    final total = MushafPage.juzStartPages.length;
    return SizedBox(
      width: 220,
      height: 214,
      // Numbers keep their written order (12 top-left, 30 bottom-right).
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RingPainter(progress: juz / total)),
            ),
            Positioned(
              left: 48,
              top: 88,
              width: 44,
              child: Text(
                '$juz',
                textAlign: TextAlign.right,
                style: _numberStyle,
              ),
            ),
            Positioned(
              left: 110,
              top: 117,
              width: 49,
              child: Text(
                '$total',
                textAlign: TextAlign.right,
                style: _numberStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  // Figma geometry inside the 220×214 group.
  static const _outer = Rect.fromLTWH(0, 19, 207, 195);
  static const _inner = Rect.fromLTWH(12, 31, 181, 170);
  static const _center = Offset(104, 116);
  static const _arcRadius = 110.0;

  /// The Figma arc starts at the upper left (about -129.5°) and runs
  /// clockwise.
  static const _startAngle = -129.5 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.ivory50
      ..strokeWidth = 1;

    canvas
      ..drawOval(_outer, Paint()..color = AppColors.beige500)
      ..drawOval(_outer.deflate(0.5), stroke)
      ..drawOval(_inner, Paint()..color = const Color(0xFFF6EADF))
      ..drawOval(_inner.deflate(0.5), stroke);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: _center, radius: _arcRadius),
        _startAngle,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = AppColors.lightGold800,
      );
    }

    // The fraction slash: top-right (126, 90) to bottom-left (81, 142).
    canvas.drawLine(
      const Offset(126, 90),
      const Offset(81, 142),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
