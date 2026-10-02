import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/extensions/context_extensions.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/utils/responsive/breakpoints.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/tafsir_cubit.dart';
import 'package:manara/features/quran/presentation/utils/quran_text_formatter.dart';
import 'package:manara/features/quran/presentation/utils/reader_palette.dart';
import 'package:manara/features/quran/presentation/widgets/reader_page_chrome.dart';
import 'package:manara/features/quran/presentation/widgets/surah_banner.dart';

/// The tafsir tab: every ayah of the reader's current page followed by its
/// tafsir. Follows page changes from [QuranReaderCubit].
class TafsirContent extends StatefulWidget {
  const TafsirContent({super.key});

  @override
  State<TafsirContent> createState() => _TafsirContentState();
}

class _TafsirContentState extends State<TafsirContent> {
  @override
  void initState() {
    super.initState();
    final page = context.read<QuranReaderCubit>().state.page;
    if (page != null) context.read<TafsirCubit>().load(page);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuranReaderCubit, QuranReaderState>(
      listenWhen: (previous, current) =>
          current.page != null && previous.page != current.page,
      listener: (context, state) =>
          context.read<TafsirCubit>().load(state.page!),
      child: const _TafsirBody(),
    );
  }
}

class _TafsirBody extends StatelessWidget {
  const _TafsirBody();

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<QuranReaderCubit>().state;
    final tafsir = context.watch<TafsirCubit>().state;
    final settings = context.watch<ReaderSettingsCubit>().state;
    final readerCubit = context.read<QuranReaderCubit>();

    if (reader.status == ReaderStatus.failure) {
      return ReaderErrorView(
        message: reader.errorMessage ?? 'حدث خطأ غير متوقع',
        onRetry: readerCubit.retry,
      );
    }
    if (tafsir.status == TafsirStatus.failure) {
      return ReaderErrorView(
        message: tafsir.errorMessage ?? 'حدث خطأ غير متوقع',
        onRetry: context.read<TafsirCubit>().retry,
      );
    }
    if (reader.page == null || tafsir.sections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final loading =
        reader.status == ReaderStatus.loading ||
        tafsir.status == TafsirStatus.loading;
    final sizes = _TafsirSizes.of(context.deviceType);

    return PageSwipeDetector(
      onNext: readerCubit.nextPage,
      onPrevious: readerCubit.previousPage,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: loading ? 0.4 : 1,
            child: _SectionList(
              // New sections start at the top.
              key: ObjectKey(tafsir.sections),
              sections: tafsir.sections,
              source: tafsir.source,
              surahs: reader.surahs,
              settings: settings,
              sizes: sizes,
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: AppSpacing.md,
            child: BookmarkRibbon(
              bookmarked: reader.isBookmarked,
              onTap: readerCubit.toggleBookmark,
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

/// Text sizes and gaps per device (Figma desktop: tafsir Tajawal Medium
/// 24/34, about 24px between an ayah and its tafsir).
class _TafsirSizes {
  const _TafsirSizes({
    required this.quran,
    required this.tafsir,
    required this.tafsirHeight,
    required this.horizontal,
    required this.ayahGap,
    required this.sectionGap,
  });

  factory _TafsirSizes.of(DeviceType device) {
    return switch (device) {
      DeviceType.mobile => const _TafsirSizes(
        quran: 23,
        tafsir: 17,
        tafsirHeight: 1.6,
        horizontal: AppSpacing.md,
        ayahGap: AppSpacing.sm,
        sectionGap: AppSpacing.xl,
      ),
      DeviceType.tablet => const _TafsirSizes(
        quran: 27,
        tafsir: 20,
        tafsirHeight: 1.5,
        horizontal: AppSpacing.lg,
        ayahGap: AppSpacing.md,
        sectionGap: AppSpacing.xxl,
      ),
      DeviceType.desktop => const _TafsirSizes(
        quran: 32,
        tafsir: 24,
        tafsirHeight: 34 / 24,
        horizontal: AppSpacing.lg,
        ayahGap: AppSpacing.xl,
        sectionGap: AppSpacing.xxxl,
      ),
    };
  }

  final double quran;
  final double tafsir;
  final double tafsirHeight;
  final double horizontal;
  final double ayahGap;
  final double sectionGap;
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.sections,
    required this.source,
    required this.surahs,
    required this.settings,
    required this.sizes,
    super.key,
  });

  final List<TafsirSection> sections;
  final TafsirSource source;
  final List<Surah> surahs;
  final ReaderSettings settings;
  final _TafsirSizes sizes;

  @override
  Widget build(BuildContext context) {
    final quranStyle = AppTypography.quran.copyWith(
      fontSize: sizes.quran * settings.fontScale,
      height: 2,
      color: ReaderPalette.text(settings.textColorIndex),
    );
    final tafsirStyle = AppTypography.bodyMedium.copyWith(
      fontSize: sizes.tafsir * settings.fontScale,
      height: sizes.tafsirHeight,
      color: AppColors.tafsirText,
    );

    return ListView.builder(
      padding: EdgeInsetsDirectional.fromSTEB(
        sizes.horizontal,
        AppSpacing.md,
        sizes.horizontal,
        AppSpacing.md,
      ),
      // The last item names the source.
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == sections.length) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
            child: Text(
              'المصدر: ${source.reference}',
              textAlign: TextAlign.center,
              style: AppTypography.captionRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        return Padding(
          padding: EdgeInsetsDirectional.only(bottom: sizes.sectionGap),
          child: TafsirSectionView(
            section: sections[index],
            surahs: surahs,
            settings: settings,
            quranStyle: quranStyle,
            tafsirStyle: tafsirStyle,
            ayahGap: sizes.ayahGap,
          ),
        );
      },
    );
  }
}

/// One or more ayahs (with ﴿n﴾ markers) followed by their tafsir.
class TafsirSectionView extends StatelessWidget {
  const TafsirSectionView({
    required this.section,
    required this.surahs,
    required this.settings,
    required this.quranStyle,
    required this.tafsirStyle,
    required this.ayahGap,
    super.key,
  });

  final TafsirSection section;
  final List<Surah> surahs;
  final ReaderSettings settings;
  final TextStyle quranStyle;
  final TextStyle tafsirStyle;
  final double ayahGap;

  String _surahName(int id) {
    for (final surah in surahs) {
      if (surah.id == id) return surah.nameArabic;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final first = section.ayahs.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (first.number == 1)
          SurahBanner(
            surahNumber: first.surahNumber,
            name: _surahName(first.surahNumber),
            style: quranStyle,
          ),
        Text(
          [
            // A no-break space keeps the ﴿n﴾ marker on the ayah's last line.
            for (final ayah in section.ayahs)
              '${QuranTextFormatter.format(ayah.text, showStopMarks: settings.showStopMarks, showTashkeel: settings.showTashkeel)}'
                  '\u00A0${QuranTextFormatter.ayahEndMarker(ayah.number)}',
          ].join(' '),
          style: quranStyle,
          textDirection: TextDirection.rtl,
        ),
        if (section.paragraphs.isNotEmpty) SizedBox(height: ayahGap),
        for (final (i, paragraph) in section.paragraphs.indexed)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: i == 0 ? 0 : AppSpacing.xs,
            ),
            child: Text(
              paragraph,
              style: tafsirStyle,
              textDirection: TextDirection.rtl,
            ),
          ),
      ],
    );
  }
}
