import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';

/// Page numbers around the current Mushaf page. The number grows toward
/// the current page (Figma: 20 → 48px), which makes it the focal point.
class PagePager extends StatelessWidget {
  const PagePager({
    required this.currentPage,
    required this.onPageSelected,
    this.radius = 4,
    super.key,
  });

  final int currentPage;
  final ValueChanged<int> onPageSelected;

  /// Number of pages shown on each side of [currentPage].
  final int radius;

  /// Font sizes from the outermost page to the current one (Figma).
  static const List<double> _sizes = [20, 24, 36, 40, 48];

  /// The visible window, clamped so it always has `2 * radius + 1` pages.
  @visibleForTesting
  List<int> get pages {
    final span = radius * 2 + 1;
    final start = (currentPage - radius).clamp(
      MushafPage.firstNumber,
      MushafPage.lastNumber - span + 1,
    );
    return [for (var i = 0; i < span; i++) start + i];
  }

  @override
  Widget build(BuildContext context) {
    // Numbers ascend from left to right in the design.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final page in pages)
              _PageNumber(
                page: page,
                distance: (page - currentPage).abs(),
                maxDistance: radius,
                onTap: () => onPageSelected(page),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.page,
    required this.distance,
    required this.maxDistance,
    required this.onTap,
  });

  final int page;
  final int distance;
  final int maxDistance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final index = (PagePager._sizes.length - 1 - distance).clamp(
      0,
      PagePager._sizes.length - 1,
    );
    final current = distance == 0;
    final opacity = current ? 1.0 : 0.55 - (distance / (maxDistance + 1)) * 0.2;

    return Semantics(
      button: true,
      selected: current,
      label: 'صفحة $page',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: PagePager._sizes[index],
                height: 1.2,
                color: AppColors.primary.withValues(alpha: opacity),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
