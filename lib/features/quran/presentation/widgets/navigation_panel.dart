import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:manara/features/quran/presentation/utils/quran_labels.dart';
import 'package:manara/features/quran/presentation/widgets/panel_header.dart';

enum _Section { surahs, juz, pages, recent, favorites }

/// "الانتقال إلى": search plus surah / juz / page / recent / favorites lists.
///
/// Calls [onNavigated] after the reader moved so a bottom sheet can close.
class NavigationPanel extends StatefulWidget {
  const NavigationPanel({required this.onClose, this.onNavigated, super.key});

  final VoidCallback onClose;
  final VoidCallback? onNavigated;

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  final _search = TextEditingController();
  _Section? _open = _Section.surahs;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _go(Future<void> Function(QuranReaderCubit cubit) navigate) {
    navigate(context.read<QuranReaderCubit>());
    widget.onNavigated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranReaderCubit>().state;
    final query = _search.text.trim();

    return Column(
      children: [
        PanelHeader(title: 'الانتقال إلى', onClose: widget.onClose),
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            children: [
              AppSearchField(
                hint: 'ابحث عن سورة...',
                controller: _search,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              if (query.isNotEmpty)
                _SurahList(
                  surahs: _filter(state.surahs, query),
                  currentId: state.currentSurah?.id,
                  emptyLabel: 'لا توجد نتائج',
                  onTap: (s) => _go((c) => c.goToSurah(s)),
                )
              else
                for (final section in _Section.values) ...[
                  _Accordion(
                    title: _title(section),
                    open: _open == section,
                    onToggle: () => setState(
                      () => _open = _open == section ? null : section,
                    ),
                    child: _content(section, state),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ],
    );
  }

  static List<Surah> _filter(List<Surah> surahs, String query) {
    final normalized = _normalize(query);
    return [
      for (final s in surahs)
        if (_normalize(s.nameArabic).contains(normalized) || '${s.id}' == query)
          s,
    ];
  }

  /// Drops diacritics and unifies alef / ya / ta-marbuta forms for matching.
  static String _normalize(String input) {
    return input
        .replaceAll(RegExp('[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }

  static String _title(_Section section) => switch (section) {
    _Section.surahs => 'السور',
    _Section.juz => 'الأجزاء',
    _Section.pages => 'الصفحات',
    _Section.recent => 'قُرئ مؤخرًا',
    _Section.favorites => 'المفضلة',
  };

  Widget _content(_Section section, QuranReaderState state) {
    switch (section) {
      case _Section.surahs:
        return _SurahList(
          surahs: state.surahs,
          currentId: state.currentSurah?.id,
          emptyLabel: 'جارٍ تحميل السور...',
          onTap: (s) => _go((c) => c.goToSurah(s)),
        );
      case _Section.juz:
        return _SimpleList(
          labels: [for (var i = 1; i <= 30; i++) 'الجزء $i'],
          onTap: (i) => _go((c) => c.goToJuz(i + 1)),
        );
      case _Section.pages:
        return _PageJump(onGo: (page) => _go((c) => c.goToPage(page)));
      case _Section.recent:
        return _PageList(
          pages: state.progress.recentPages,
          surahs: state.surahs,
          emptyLabel: 'لم تقرأ أي صفحة بعد',
          onTap: (p) => _go((c) => c.goToPage(p)),
        );
      case _Section.favorites:
        return _PageList(
          pages: state.progress.bookmarkedPages,
          surahs: state.surahs,
          emptyLabel: 'لا توجد صفحات محفوظة',
          onTap: (p) => _go((c) => c.goToPage(p)),
        );
    }
  }
}

class _Accordion extends StatelessWidget {
  const _Accordion({
    required this.title,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: Material(
            color: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdAll,
              side: BorderSide(),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.subtitleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? -0.25 : 0,
                      duration: const Duration(milliseconds: 150),
                      // Points toward the reading end, down when open.
                      child: const Icon(
                        Icons.chevron_left,
                        color: AppColors.green900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                  child: child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected ? AppColors.surfaceMuted : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.borderStrong,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTypography.smallRegular.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.green900,
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

class _SurahList extends StatelessWidget {
  const _SurahList({
    required this.surahs,
    required this.currentId,
    required this.emptyLabel,
    required this.onTap,
  });

  final List<Surah> surahs;
  final int? currentId;
  final String emptyLabel;
  final ValueChanged<Surah> onTap;

  @override
  Widget build(BuildContext context) {
    if (surahs.isEmpty) return _Empty(label: emptyLabel);
    return Column(
      children: [
        for (final surah in surahs)
          _Row(
            title: surah.nameArabic,
            subtitle: QuranLabels.listSubtitle(surah),
            selected: surah.id == currentId,
            onTap: () => onTap(surah),
          ),
      ],
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({required this.labels, required this.onTap});

  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          _Row(title: labels[i], onTap: () => onTap(i)),
      ],
    );
  }
}

class _PageList extends StatelessWidget {
  const _PageList({
    required this.pages,
    required this.surahs,
    required this.emptyLabel,
    required this.onTap,
  });

  final List<int> pages;
  final List<Surah> surahs;
  final String emptyLabel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return _Empty(label: emptyLabel);
    return Column(
      children: [
        for (final page in pages)
          _Row(
            title: 'صفحة $page',
            subtitle: _surahNameForPage(page),
            onTap: () => onTap(page),
          ),
      ],
    );
  }

  /// The surah that starts last on or before [page].
  String? _surahNameForPage(int page) {
    Surah? match;
    for (final surah in surahs) {
      if (surah.firstPage <= page) match = surah;
    }
    return match == null ? null : 'سورة ${match.nameArabic}';
  }
}

class _PageJump extends StatefulWidget {
  const _PageJump({required this.onGo});

  final ValueChanged<int> onGo;

  @override
  State<_PageJump> createState() => _PageJumpState();
}

class _PageJumpState extends State<_PageJump> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final page = int.tryParse(_controller.text.trim());
    if (page == null ||
        page < MushafPage.firstNumber ||
        page > MushafPage.lastNumber) {
      setState(
        () => _error =
            'أدخل رقمًا من ${MushafPage.firstNumber} إلى ${MushafPage.lastNumber}',
      );
      return;
    }
    setState(() => _error = null);
    widget.onGo(page);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'رقم الصفحة',
          hint: '${MushafPage.firstNumber} - ${MushafPage.lastNumber}',
          controller: _controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
            child: Text(
              _error!,
              style: AppTypography.labelRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(label: 'انتقال', onPressed: _submit, expand: true),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Center(
        child: Text(
          label,
          style: AppTypography.captionRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
