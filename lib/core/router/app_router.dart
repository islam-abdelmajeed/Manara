import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/features/home/presentation/pages/home_page.dart';
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
      builder: (context, state) => const QuranReaderPage(),
    ),
  ],
);
