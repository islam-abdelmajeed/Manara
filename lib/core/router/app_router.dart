import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/features/home/presentation/pages/home_page.dart';
import 'package:manara/features/prayer/presentation/pages/prayer_page.dart';
import 'package:manara/features/prayer/presentation/widgets/prayer_layout.dart';
import 'package:manara/features/quran/presentation/pages/quran_index_page.dart';
import 'package:manara/features/quran/presentation/pages/quran_reader_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.quran,
      builder: (context, state) => const QuranIndexPage(),
      routes: [
        GoRoute(
          path: 'read',
          builder: (context, state) => QuranReaderPage(
            initialPage: int.tryParse(state.uri.queryParameters['page'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.prayer,
      pageBuilder: (context, state) => _tab(
        state,
        PrayerPage(
          tab: PrayerTab.times,
          showQibla: state.uri.queryParameters['section'] == 'qibla',
        ),
      ),
      routes: [
        for (final tab in [
          PrayerTab.monthly,
          PrayerTab.alerts,
          PrayerTab.settings,
        ])
          GoRoute(
            path: tab.route.substring(AppRoutes.prayer.length + 1),
            pageBuilder: (context, state) => _tab(
              state,
              PrayerPage(tab: tab, cities: state.uri.queryParameters['cities']),
            ),
          ),
      ],
    ),
  ],
);

/// Switching between prayer tabs swaps the page in place. The key adds the
/// query to the route's own path, so a new query (e.g. `?cities=EG`)
/// builds the page afresh while the tab under it keeps its key.
Page<void> _tab(GoRouterState state, Widget child) => NoTransitionPage<void>(
  key: ValueKey('${state.matchedLocation}?${state.uri.query}'),
  child: child,
);
