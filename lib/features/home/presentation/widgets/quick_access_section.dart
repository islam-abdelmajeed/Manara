import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_nav_bar.dart';
import 'package:manara/core/widgets/design_box.dart';
import 'package:manara/features/home/presentation/widgets/home_layout.dart';

class _QuickItem {
  const _QuickItem(
    this.title,
    this.subtitle,
    this.image,
    this.imageSize, [
    this.route,
  ]);

  final String title;
  final String subtitle;
  final String image;

  /// Figma draws each illustration at its own size.
  final Size imageSize;
  final String? route;
}

/// "الوصول السريع": five illustrated shortcut cards.
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  static const _items = [
    _QuickItem(
      'القرآن الكريم',
      'اقرأ واستمع وتدبّر',
      AppImages.quickQuran,
      Size(234, 188),
      AppRoutes.quran,
    ),
    _QuickItem(
      'القبلة',
      'اعرف اتجاه القبلة',
      AppImages.quickQibla,
      Size(228, 196),
    ),
    _QuickItem(
      'الصلاة',
      'مواقيت الصلاة والأذان',
      AppImages.quickPrayer,
      Size(236, 194),
    ),
    _QuickItem(
      'الأذكار',
      'أذكاري اليومية',
      AppImages.quickAdhkar,
      Size(234, 176),
    ),
    _QuickItem(
      'التسبيح',
      'سبّح واستغفر',
      AppImages.quickTasbih,
      Size(236, 200),
    ),
  ];

  static const double _gap = 27;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle('الوصول السريع'),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1300
                ? 5
                : width >= 1000
                ? 4
                : width >= 700
                ? 3
                : 2;
            final gap = width < 600 ? AppSpacing.md : _gap;
            final cardWidth = math.min(
              _QuickCard.size.width,
              (width - gap * (columns - 1)) / columns,
            );
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: AppSpacing.xl,
              children: [
                for (final item in _items)
                  SizedBox(
                    width: cardWidth,
                    child: DesignBox(
                      size: _QuickCard.size,
                      child: _QuickCard(item: item),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.item});

  static const size = Size(252, 308);
  static const _radius = BorderRadius.all(Radius.circular(18));

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        // Figma draws no fill; the page color keeps the shadow outside.
        color: AppColors.readerBackground,
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(color: AppColors.darkBrown400),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final route = item.route;
            if (route == null) {
              showComingSoon(context);
            } else {
              context.go(route);
            }
          },
          child: Semantics(
            button: true,
            label: '${item.title}، ${item.subtitle}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    item.image,
                    width: item.imageSize.width,
                    height: item.imageSize.height,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.subtitleBold.copyWith(
                      color: AppColors.gold900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.subtitleMedium.copyWith(
                      color: AppColors.lightGold900,
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
