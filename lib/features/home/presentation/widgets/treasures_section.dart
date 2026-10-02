import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/app_nav_bar.dart';
import 'package:manara/features/home/presentation/widgets/home_layout.dart';

class _Treasure {
  const _Treasure(this.title, this.image);

  /// Spoken label; the visible title is part of the artwork.
  final String title;
  final String image;
}

/// "كنوز منارة": horizontally scrolling banners that run past the page edge.
class TreasuresSection extends StatelessWidget {
  const TreasuresSection({required this.sidePadding, super.key});

  final double sidePadding;

  static const _items = [
    _Treasure('على خطاهم: نتعلم من سير الصالحين', AppImages.treasureFootsteps),
    _Treasure('تحف الأطفال: رحلة ممتعة لتربية الطفل', AppImages.treasureKids),
    _Treasure(
      'التسميع بالصوت: اسمع تلاوتك وسجّلها',
      AppImages.treasureRecitation,
    ),
    _Treasure('غرف صوتية للتسميع', AppImages.treasureVoiceRooms),
  ];

  static const Size _designItem = Size(568, 383);
  static const double _gap = 50;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final compact = screen < 700;
    // Android builds the first frame at width 0, before the window metrics
    // arrive; a negative size there throws and breaks the whole section.
    final itemWidth = math.max(
      0.0,
      math.min(_designItem.width, (screen - sidePadding) * 0.85),
    );
    final itemHeight = itemWidth * _designItem.height / _designItem.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding + 1),
          child: const HomeSectionTitle('كنوز منارة', padding: 0),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: itemHeight,
          child: ScrollConfiguration(
            // Let mouse users drag the row on web and desktop.
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsetsDirectional.only(
                start: compact ? sidePadding : sidePadding + 4,
                end: sidePadding,
              ),
              itemCount: _items.length,
              separatorBuilder: (_, _) =>
                  SizedBox(width: compact ? AppSpacing.md : _gap),
              itemBuilder: (context, i) =>
                  _Banner(item: _items[i], width: itemWidth),
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.item, required this.width});

  final _Treasure item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.title,
      child: Material(
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: Ink.image(
          image: AssetImage(item.image),
          width: width,
          fit: BoxFit.cover,
          child: InkWell(onTap: () => showComingSoon(context)),
        ),
      ),
    );
  }
}
