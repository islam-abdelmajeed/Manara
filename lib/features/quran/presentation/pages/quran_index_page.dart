import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/di/injection.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/presentation/cubit/quran_index_cubit.dart';
import 'package:manara/features/quran/presentation/utils/quran_labels.dart';
import 'package:manara/features/quran/presentation/widgets/index/index_side_cards.dart';
import 'package:manara/features/quran/presentation/widgets/index/index_style.dart';
import 'package:manara/features/quran/presentation/widgets/index/index_tabs.dart';
import 'package:manara/features/quran/presentation/widgets/index/quran_index_card.dart';

class QuranIndexPage extends StatelessWidget {
  const QuranIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuranIndexCubit>()..load(),
      child: const QuranIndexView(),
    );
  }
}

/// Quran index (Figma "Desktop - 4"). Expects [QuranIndexCubit] above.
///
/// From [wideBreakpoint] up: search and tabs on top, the summary cards in a
/// 320 column beside a four-column grid. Narrower: one stacked column.
class QuranIndexView extends StatefulWidget {
  const QuranIndexView({super.key});

  static const double wideBreakpoint = AppNavBar.compactBreakpoint;

  @override
  State<QuranIndexView> createState() => _QuranIndexViewState();
}

class _QuranIndexViewState extends State<QuranIndexView> {
  final _search = TextEditingController();

  // The reader is a sub-route, so this page stays mounted underneath it;
  // progress is re-read whenever the index becomes the current page again.
  GoRouter? _router;
  String? _path;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router == _router) return;
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = router;
    _path = router?.state.uri.path;
    router?.routerDelegate.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final path = _router?.state.uri.path;
    if (path == AppRoutes.quran && _path != AppRoutes.quran) {
      context.read<QuranIndexCubit>().refreshProgress();
    }
    _path = path;
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      active: NavItem.quran,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= QuranIndexView.wideBreakpoint;
          return SingleChildScrollView(
            child: SafeArea(
              top: false,
              child: wide
                  ? _WideLayout(search: _search)
                  : _StackedLayout(search: _search),
            ),
          );
        },
      ),
    );
  }
}

void _openReader(BuildContext context, [int? page]) {
  context.go(
    page == null ? AppRoutes.quranReader : AppRoutes.quranReaderAt(page),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      hint: 'ابحث عن سورة أو آية...',
      controller: controller,
      onChanged: context.read<QuranIndexCubit>().search,
      fillColor: IndexStyle.cardColor,
      iconAtEnd: true,
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tab = context.select((QuranIndexCubit c) => c.state.tab);
    return IndexTabs(
      selected: tab,
      onSelected: context.read<QuranIndexCubit>().selectTab,
      compact: compact,
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.search});

  final TextEditingController search;

  static const double _sideWidth = 320;
  static const double _designWidth = 1440;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _designWidth),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(60, 44, 52, 56),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: _sideWidth,
                    child: _SearchField(controller: search),
                  ),
                  const SizedBox(width: 46),
                  const Expanded(child: _Tabs()),
                ],
              ),
              const SizedBox(height: 35),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _sideWidth,
                    child: _SideCards(gap: 38, includeMostRead: true),
                  ),
                  SizedBox(width: 26),
                  _FadedRule(),
                  SizedBox(width: 19),
                  Expanded(
                    child: _Listing(columnGap: 20, rowGap: 29, fixedColumns: 4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackedLayout extends StatelessWidget {
  const _StackedLayout({required this.search});

  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width < 600 ? AppSpacing.md : AppSpacing.xl;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.lg,
        gutter,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchField(controller: search),
          const SizedBox(height: AppSpacing.md),
          _Tabs(compact: width < 600),
          const SizedBox(height: AppSpacing.lg),
          const _SideCards(gap: AppSpacing.md, includeMostRead: false),
          const SizedBox(height: AppSpacing.xl),
          _Listing(
            columnGap: width < 600 ? AppSpacing.sm : AppSpacing.lg,
            rowGap: width < 600 ? AppSpacing.sm : AppSpacing.lg,
          ),
          const SizedBox(height: AppSpacing.xl),
          MostReadCard(onOpen: (s) => _openReader(context, s.firstPage)),
        ],
      ),
    );
  }
}

/// Daily wird and continue-reading cards, plus "most read" in the side
/// column. Side by side when stacked on wide-enough screens.
class _SideCards extends StatelessWidget {
  const _SideCards({required this.gap, required this.includeMostRead});

  final double gap;
  final bool includeMostRead;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranIndexCubit>().state;
    final started = state.progress.hasStarted;

    final wird = DailyWirdCard(
      pagesRead: state.pagesReadToday,
      goal: ReaderProgress.dailyWirdPages,
      onStart: () => _openReader(context),
    );
    final resume = ContinueReadingCard(
      lastRead: state.lastRead,
      hasStarted: started,
      onContinue: () => _openReader(context, started ? null : 1),
    );

    if (!includeMostRead && MediaQuery.sizeOf(context).width >= 760) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: wird),
            SizedBox(width: gap),
            Expanded(child: resume),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        wird,
        SizedBox(height: gap),
        resume,
        if (includeMostRead) ...[
          SizedBox(height: gap),
          MostReadCard(onOpen: (s) => _openReader(context, s.firstPage)),
        ],
      ],
    );
  }
}

/// Vertical rule between the side column and the grid, fading at both ends.
class _FadedRule extends StatelessWidget {
  const _FadedRule();

  static const Color _color = Color(0xFFB7B0A6);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 185),
      child: Container(
        width: 1,
        height: 430,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _color.withValues(alpha: 0),
              _color,
              _color,
              _color.withValues(alpha: 0),
            ],
            stops: const [0, 0.3, 0.6, 1],
          ),
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry(this.number, this.title, this.subtitle, this.page);

  final int number;
  final String title;
  final String subtitle;

  /// Mushaf page the card opens.
  final int page;
}

List<_Entry> _entriesOf(QuranIndexState state) {
  _Entry pageEntry(int page) {
    final surah = state.surahAtPage(page);
    return _Entry(
      page,
      surah == null ? 'صفحة $page' : 'سورة ${surah.nameArabic}',
      'صفحة $page | الجزء ${MushafPage.juzOf(page)}',
      page,
    );
  }

  return switch (state.tab) {
    QuranIndexTab.surahs => [
      for (final surah in state.filteredSurahs)
        _Entry(
          surah.id,
          surah.nameArabic,
          QuranLabels.cardSubtitle(surah),
          surah.firstPage,
        ),
    ],
    QuranIndexTab.juz => [
      for (var juz = 1; juz <= QuranLabels.juzStartPages.length; juz++)
        () {
          final page = QuranLabels.juzStartPages[juz - 1];
          final surah = state.surahAtPage(page);
          return _Entry(
            juz,
            QuranLabels.juzName(juz),
            surah == null ? 'صفحة $page' : '${surah.nameArabic} | صفحة $page',
            page,
          );
        }(),
    ],
    QuranIndexTab.recent => [
      for (final page in state.progress.recentPages) pageEntry(page),
    ],
    QuranIndexTab.favorites => [
      for (final page in state.progress.bookmarkedPages.reversed)
        pageEntry(page),
    ],
  };
}

String _emptyMessage(QuranIndexState state) {
  return switch (state.tab) {
    QuranIndexTab.surahs => 'لا توجد سورة تطابق "${state.query.trim()}"',
    QuranIndexTab.juz => '',
    QuranIndexTab.recent => 'لم تقرأ أي صفحة بعد',
    QuranIndexTab.favorites =>
      'لا توجد صفحات في المفضلة بعد.\nاحفظ الصفحة من القارئ لتجدها هنا.',
  };
}

/// Grid of the current tab, "عرض المزيد", and the loading / error / empty
/// states.
class _Listing extends StatelessWidget {
  const _Listing({
    required this.columnGap,
    required this.rowGap,
    this.fixedColumns,
  });

  final double columnGap;
  final double rowGap;

  /// Figma's four columns on desktop; otherwise as many as fit.
  final int? fixedColumns;

  static const double _minCardWidth = 150;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranIndexCubit>().state;
    final cubit = context.read<QuranIndexCubit>();

    // The juz tab is static and the page tabs only need progress, so the
    // surah list failing blocks the surah tab alone.
    final needsSurahs = state.tab == QuranIndexTab.surahs;
    if (needsSurahs &&
        (state.status == QuranIndexStatus.initial ||
            state.status == QuranIndexStatus.loading)) {
      return const _Message(child: CircularProgressIndicator());
    }
    if (needsSurahs && state.status == QuranIndexStatus.failure) {
      return _Message(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تعذر تحميل السور',
              style: AppTypography.bodyMedium.copyWith(
                color: IndexStyle.titleColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: cubit.load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final entries = _entriesOf(state);
    if (entries.isEmpty) {
      return _Message(
        child: Text(
          _emptyMessage(state),
          textAlign: TextAlign.center,
          style: AppTypography.bodyRegular.copyWith(
            color: IndexStyle.mutedText,
          ),
        ),
      );
    }

    final visible = entries.take(state.visibleCount).toList();

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                fixedColumns ??
                ((constraints.maxWidth + columnGap) /
                        (_minCardWidth + columnGap))
                    .floor()
                    .clamp(2, 4);
            return _Grid(
              entries: visible,
              columns: columns,
              columnGap: columnGap,
              rowGap: rowGap,
            );
          },
        ),
        if (entries.length > visible.length) ...[
          const SizedBox(height: 38),
          _ShowMoreButton(onPressed: cubit.showMore),
        ],
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.entries,
    required this.columns,
    required this.columnGap,
    required this.rowGap,
  });

  final List<_Entry> entries;
  final int columns;
  final double columnGap;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final rows = (entries.length / columns).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) SizedBox(height: rowGap),
          Row(
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: columnGap),
                Expanded(
                  child: r * columns + c < entries.length
                      ? _card(context, entries[r * columns + c])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, _Entry entry) {
    return QuranIndexCard(
      number: entry.number,
      title: entry.title,
      subtitle: entry.subtitle,
      onTap: () => _openReader(context, entry.page),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Center(child: child),
    );
  }
}

/// "عرض المزيد": white pill, 32 high, gold outline.
class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.white50,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.lightGold300),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 32,
            width: 136,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'عرض المزيد',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.darkBrown800,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const AppIcon(
                  AppIcons.arrowDown,
                  size: 16,
                  color: AppColors.darkBrown800,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
