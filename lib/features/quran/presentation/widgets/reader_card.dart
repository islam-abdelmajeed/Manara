import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/extensions/context_extensions.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/utils/responsive/breakpoints.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:manara/features/quran/presentation/utils/reader_palette.dart';
import 'package:manara/features/quran/presentation/widgets/mushaf_frame.dart';
import 'package:manara/features/quran/presentation/widgets/mushaf_text.dart';
import 'package:manara/features/quran/presentation/widgets/page_pager.dart';
import 'package:manara/features/quran/presentation/widgets/reader_header.dart';

/// The Mushaf card: header, page content for the selected tab, and pager.
class ReaderCard extends StatelessWidget {
  const ReaderCard({
    required this.onNavigationTap,
    required this.onSettingsTap,
    super.key,
  });

  final VoidCallback onNavigationTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranReaderCubit>().state;
    final settings = context.watch<ReaderSettingsCubit>().state;
    final cubit = context.read<QuranReaderCubit>();
    final background = ReaderPalette.background(settings.backgroundColorIndex);

    return MushafFrame(
      color: background,
      child: Column(
        children: [
          ReaderHeader(
            surah: state.currentSurah,
            compact: context.isMobile,
            onNavigationTap: onNavigationTap,
            onSettingsTap: onSettingsTap,
            onPlayTap: () => showAppToast(context, 'ميزة الاستماع قريبًا'),
          ),
          Expanded(
            child: switch (state.tab) {
              ReaderTab.reading => _ReadingContent(
                state: state,
                settings: settings,
              ),
              _ => const _ComingSoon(),
            },
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.sm,
            ),
            child: PagePager(
              currentPage: state.pageNumber,
              radius: context.isMobile ? 3 : 4,
              onPageSelected: cubit.goToPage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingContent extends StatelessWidget {
  const _ReadingContent({required this.state, required this.settings});

  final QuranReaderState state;
  final ReaderSettings settings;

  double _baseFontSize(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 26,
      DeviceType.tablet => 30,
      DeviceType.desktop => 36,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranReaderCubit>();
    final page = state.page;

    if (state.status == ReaderStatus.failure) {
      return _ErrorView(
        message: state.errorMessage ?? 'حدث خطأ غير متوقع',
        onRetry: cubit.retry,
      );
    }
    if (page == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final loading = state.status == ReaderStatus.loading;
    final horizontal = context.isMobile ? AppSpacing.md : AppSpacing.xxl;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Numbers ascend to the right in the pager, so dragging left goes on.
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) cubit.nextPage();
        if (velocity > 300) cubit.previousPage();
      },
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: loading ? 0.4 : 1,
            child: SingleChildScrollView(
              key: ValueKey(page.number),
              padding: EdgeInsetsDirectional.fromSTEB(
                horizontal,
                AppSpacing.md,
                horizontal,
                AppSpacing.md,
              ),
              child: MushafText(
                page: page,
                settings: settings,
                baseFontSize: _baseFontSize(context),
                surahs: state.surahs,
                selectedAyahKey: state.selectedAyahKey,
                onAyahTap: cubit.selectAyah,
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: AppSpacing.md,
            child: _BookmarkRibbon(
              bookmarked: state.isBookmarked,
              onTap: cubit.toggleBookmark,
            ),
          ),
          if (loading)
            const PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }
}

class _BookmarkRibbon extends StatelessWidget {
  const _BookmarkRibbon({required this.bookmarked, required this.onTap});

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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'قريبًا إن شاء الله',
        style: AppTypography.h5Medium.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
