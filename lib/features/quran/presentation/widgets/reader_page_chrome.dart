import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';

/// Turns pages with a horizontal swipe. Numbers ascend to the right in the
/// pager, so dragging left goes on.
class PageSwipeDetector extends StatelessWidget {
  const PageSwipeDetector({
    required this.onNext,
    required this.onPrevious,
    required this.child,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) onNext();
        if (velocity > 300) onPrevious();
      },
      child: child,
    );
  }
}

/// Bookmark toggle pinned to the top corner of the page.
class BookmarkRibbon extends StatelessWidget {
  const BookmarkRibbon({
    required this.bookmarked,
    required this.onTap,
    super.key,
  });

  final bool bookmarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: bookmarked ? 'إزالة من المفضلة' : 'حفظ الصفحة',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: AppIcon(
        bookmarked ? AppIcons.bookmarkCheck : AppIcons.bookmarkAdd,
        size: 32,
        color: AppColors.green900,
      ),
    );
  }
}

class ReaderErrorView extends StatelessWidget {
  const ReaderErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLargeMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
