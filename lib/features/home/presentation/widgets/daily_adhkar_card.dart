import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';

/// Morning or evening wording of the adhkar card.
class AdhkarPeriod {
  const AdhkarPeriod._({
    required this.headline,
    required this.body,
    required this.button,
    required this.icon,
  });

  /// Figma shows the morning version.
  static const morning = AdhkarPeriod._(
    headline: 'ابدأ يومك بالأذكار',
    body: 'حصِّن يومك بذكر الله وابدأ صباحك بالطمأنينة.',
    button: 'أذكار الصباح',
    icon: AppIcons.sun,
  );

  static const evening = AdhkarPeriod._(
    headline: 'اختم يومك بالأذكار',
    body: 'حصِّن مساءك بذكر الله واختم يومك بالطمأنينة.',
    button: 'أذكار المساء',
    icon: AppIcons.moon,
  );

  /// Morning adhkar until mid-afternoon, evening adhkar after.
  static AdhkarPeriod of(DateTime now) =>
      now.hour >= 4 && now.hour < 15 ? morning : evening;

  final String headline;
  final String body;
  final String button;
  final String icon;
}

/// "أذكارك اليومية" banner.
class DailyAdhkarCard extends StatelessWidget {
  const DailyAdhkarCard({required this.period, super.key});

  final AdhkarPeriod period;

  static const Size designSize = Size(862, 400);
  static const double minDesignWidth = 640;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minDesignWidth) {
          return DesignBox(
            size: designSize,
            child: _DesignLayout(period: period),
          );
        }
        return _CompactLayout(period: period);
      },
    );
  }
}

abstract final class _Style {
  static const heading = AppColors.green900;
  static const quote = AppColors.gold400;
  static const accent = AppColors.green500;

  static final title = AppTypography.h1Medium.copyWith(color: heading);
  static final subtitle = AppTypography.subtitleMedium.copyWith(color: heading);
  static const headline = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontWeight: AppTypography.medium,
    fontSize: 40,
    height: 1,
    color: accent,
  );
  static final body = AppTypography.subtitleMedium.copyWith(
    color: Colors.black,
  );

  static const titleText = 'أذكارك اليومية';
  static const subtitleText = 'طمأنينة للقلب، وذكرٌ يقرّبك إلى الله.';
}

class _DesignLayout extends StatelessWidget {
  const _DesignLayout({required this.period});

  final AdhkarPeriod period;

  static const _radius = BorderRadius.all(Radius.circular(48));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppImages.cardAdhkar,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              left: 323,
              top: 37,
              width: 499,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_Style.titleText, style: _Style.title),
                  Text(_Style.subtitleText, style: _Style.subtitle),
                  const SizedBox(height: 47),
                  Center(
                    child: _Headline(period: period, style: _Style.headline),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      period.body,
                      textAlign: TextAlign.center,
                      style: _Style.body,
                    ),
                  ),
                  const SizedBox(height: 49),
                  Center(child: _AdhkarButton(period: period)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.period});

  final AdhkarPeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EADD),
        borderRadius: const BorderRadius.all(Radius.circular(32)),
        border: Border.all(color: const Color(0xFFDAB797), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _Style.titleText,
            style: AppTypography.h4Medium.copyWith(color: _Style.heading),
          ),
          Text(
            _Style.subtitleText,
            style: AppTypography.bodyMedium.copyWith(color: _Style.heading),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: _Headline(
              period: period,
              style: _Style.headline.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            period.body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.black,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(child: _AdhkarButton(period: period)),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.period, required this.style});

  final AdhkarPeriod period;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final mark = style.copyWith(color: _Style.quote);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Figma uses the same mark on both sides.
          Text('“', style: mark),
          const SizedBox(width: 8),
          Text(period.headline, style: style),
          const SizedBox(width: 8),
          Text('“', style: mark),
        ],
      ),
    );
  }
}

class _AdhkarButton extends StatelessWidget {
  const _AdhkarButton({required this.period});

  final AdhkarPeriod period;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Style.accent,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: () => showComingSoon(context),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                period.button,
                style: AppTypography.subtitleMedium.copyWith(
                  color: AppColors.ivory50,
                ),
              ),
              const SizedBox(width: 2),
              AppIcon(period.icon, size: 30, color: AppColors.beige50),
            ],
          ),
        ),
      ),
    );
  }
}
