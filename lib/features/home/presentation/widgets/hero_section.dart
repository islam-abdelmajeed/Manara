import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_icon.dart';

/// Welcome banner from Figma: blurred mosque photo, a soft white glow behind
/// the text, the verse, and the "start your journey" button.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  static const double _designHeight = 640;
  static const double _designWidth = 1440;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final height = (width * _designHeight / _designWidth).clamp(
      440.0,
      _designHeight,
    );

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Figma: 15px layer blur; the photo overhangs 9px on each side so
          // the blurred edges stay out of view.
          Positioned(
            left: -9,
            right: -9,
            top: 0,
            bottom: 0,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image.asset(
                AppImages.homeHero,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
          // Figma: 591×547 ellipse, white 82%, 153px layer blur.
          Positioned(
            top: 19,
            left: 0,
            right: 0,
            child: Center(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 76, sigmaY: 76),
                child: Container(
                  width: compact ? 360 : 591,
                  height: compact ? 400 : 547,
                  decoration: const ShapeDecoration(
                    color: Color(0xD1FFFFFF),
                    shape: OvalBorder(),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(child: _Content(compact: compact)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.compact});

  final bool compact;

  /// Al-Kahf 18:24.
  static const _verse = 'وَاذْكُر رَّبَّكَ إِذَا نَسِيتَ';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'مرحبًا بك في منارة',
          textAlign: TextAlign.center,
          style:
              (compact ? AppTypography.subtitleMedium : AppTypography.h2Medium)
                  .copyWith(color: AppColors.darkBrown800),
        ),
        SizedBox(height: compact ? AppSpacing.sm : 26),
        Text(
          _verse,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.bold,
            fontSize: compact ? 32 : 48,
            height: 67 / 48,
            color: AppColors.darkBrown900,
          ),
        ),
        Text(
          'رفيقك للقرآن والعبادة والمعرفة\nكل ما تحتاجه في مكان واحد',
          textAlign: TextAlign.center,
          style:
              (compact
                      ? AppTypography.bodyMedium.copyWith(height: 1.5)
                      : AppTypography.subtitleMedium)
                  .copyWith(color: AppColors.darkBrown900),
        ),
        SizedBox(height: compact ? AppSpacing.lg : 30),
        const _StartButton(),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightGold900,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: () => context.go(AppRoutes.quran),
        borderRadius: AppRadius.smAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ابدأ رحلتك الآن',
                style: AppTypography.bodyLargeMedium.copyWith(
                  color: const Color(0xFFD9D9D9),
                ),
              ),
              const SizedBox(width: 17),
              // The asset points toward the reading end (left).
              const AppIcon(AppIcons.arrowRight, size: 35, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
