import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manara/core/di/injection.dart';
import 'package:manara/core/extensions/context_extensions.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart';
import 'package:manara/features/quran/presentation/cubit/tafsir_cubit.dart';
import 'package:manara/features/quran/presentation/widgets/mushaf_frame.dart';
import 'package:manara/features/quran/presentation/widgets/navigation_panel.dart';
import 'package:manara/features/quran/presentation/widgets/reader_card.dart';
import 'package:manara/features/quran/presentation/widgets/settings_panel.dart';

class QuranReaderPage extends StatelessWidget {
  const QuranReaderPage({this.initialPage, super.key});

  /// Page to open; the last read page when `null`.
  final int? initialPage;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<QuranReaderCubit>()..init(initialPage: initialPage),
        ),
        BlocProvider(create: (_) => getIt<ReaderSettingsCubit>()..load()),
        BlocProvider(create: (_) => getIt<TafsirCubit>()),
      ],
      child: const QuranReaderView(),
    );
  }
}

/// Reader layout. Expects [QuranReaderCubit], [ReaderSettingsCubit] and
/// [TafsirCubit] above.
///
/// Desktop shows navigation / settings as a side panel next to the Mushaf;
/// smaller screens open them as bottom sheets.
class QuranReaderView extends StatelessWidget {
  const QuranReaderView({super.key});

  static const _tabs = [
    AppTabItem(label: 'قراءة'),
    AppTabItem(label: 'تفسير'),
    AppTabItem(label: 'ترجمة'),
    AppTabItem(label: 'ترتيل'),
  ];

  static const double _panelWidth = 386;
  static const double _cardMaxWidth = 924;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranReaderCubit>().state;
    final cubit = context.read<QuranReaderCubit>();
    final padding = context.isMobile ? AppSpacing.sm : AppSpacing.xl;

    return AppScaffold(
      active: NavItem.quran,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            AppSpacing.md,
            padding,
            padding,
          ),
          child: Column(
            children: [
              AppTabBar(
                items: _tabs,
                selectedIndex: state.tab.index,
                onChanged: (i) => cubit.selectTab(ReaderTab.values[i]),
              ),
              SizedBox(
                height: context.isMobile ? AppSpacing.sm : AppSpacing.md,
              ),
              Expanded(
                child: context.isDesktop
                    ? _DesktopLayout(state: state)
                    : ReaderCard(
                        onNavigationTap: () =>
                            _openSheet(context, ReaderPanel.navigation),
                        onSettingsTap: () =>
                            _openSheet(context, ReaderPanel.settings),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openSheet(BuildContext context, ReaderPanel panel) {
    final reader = context.read<QuranReaderCubit>();
    final settings = context.read<ReaderSettingsCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.readerBackground,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        void close() => Navigator.of(sheetContext).pop();
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: reader),
            BlocProvider.value(value: settings),
          ],
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: panel == ReaderPanel.navigation
                  ? NavigationPanel(onClose: close, onNavigated: close)
                  : SettingsPanel(onClose: close),
            ),
          ),
        );
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.state});

  final QuranReaderState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranReaderCubit>();
    final navigationOpen = state.panel == ReaderPanel.navigation;
    final settingsOpen = state.panel == ReaderPanel.settings;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Navigation opens on the reading-start side, settings on the end.
        if (navigationOpen) ...[
          SizedBox(
            width: QuranReaderView._panelWidth,
            child: MushafFrame(
              child: NavigationPanel(onClose: cubit.closePanel),
            ),
          ),
          const SizedBox(width: 50),
        ],
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: QuranReaderView._cardMaxWidth,
            ),
            child: ReaderCard(
              onNavigationTap: () => cubit.openPanel(ReaderPanel.navigation),
              onSettingsTap: () => cubit.openPanel(ReaderPanel.settings),
            ),
          ),
        ),
        if (settingsOpen) ...[
          const SizedBox(width: 50),
          SizedBox(
            width: QuranReaderView._panelWidth,
            child: MushafFrame(child: SettingsPanel(onClose: cubit.closePanel)),
          ),
        ],
      ],
    );
  }
}
