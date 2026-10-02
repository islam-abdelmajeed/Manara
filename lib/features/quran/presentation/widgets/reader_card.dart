import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/extensions/context_extensions.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/utils/responsive/breakpoints.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/tafsir_cubit.dart';
import 'package:manara/features/quran/presentation/utils/reader_palette.dart';
import 'package:manara/features/quran/presentation/widgets/mushaf_frame.dart';
import 'package:manara/features/quran/presentation/widgets/mushaf_text.dart';
import 'package:manara/features/quran/presentation/widgets/page_pager.dart';
import 'package:manara/features/quran/presentation/widgets/reader_header.dart';
import 'package:manara/features/quran/presentation/widgets/reader_page_chrome.dart';
import 'package:manara/features/quran/presentation/widgets/tafsir_content.dart';
import 'package:manara/features/quran/presentation/widgets/tafsir_selector.dart';

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
            // The tafsir tab swaps the play button for the tafsir picker.
            action: state.tab == ReaderTab.tafsir
                ? const _TafsirPicker()
                : null,
          ),
          Expanded(
            child: switch (state.tab) {
              ReaderTab.reading => _ReadingContent(
                state: state,
                settings: settings,
              ),
              ReaderTab.tafsir => const TafsirContent(),
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
      DeviceType.mobile => 23,
      DeviceType.tablet => 27,
      DeviceType.desktop => 32,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranReaderCubit>();
    final page = state.page;

    if (state.status == ReaderStatus.failure) {
      return ReaderErrorView(
        message: state.errorMessage ?? 'حدث خطأ غير متوقع',
        onRetry: cubit.retry,
      );
    }
    if (page == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final loading = state.status == ReaderStatus.loading;
    final horizontal = context.isMobile ? AppSpacing.md : AppSpacing.xxl;

    return PageSwipeDetector(
      onNext: cubit.nextPage,
      onPrevious: cubit.previousPage,
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
            child: BookmarkRibbon(
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

class _TafsirPicker extends StatelessWidget {
  const _TafsirPicker();

  @override
  Widget build(BuildContext context) {
    final source = context.select((TafsirCubit c) => c.state.source);
    return TafsirSelector(
      selected: source,
      onSelected: context.read<TafsirCubit>().selectSource,
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
