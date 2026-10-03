import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manara/core/constants/app_constants.dart';
import 'package:manara/core/di/injection.dart';
import 'package:manara/core/router/app_router.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_alerts_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:manara/features/prayer/presentation/widgets/alerts/prayer_alert_scheduler.dart';

class ManaraApp extends StatelessWidget {
  const ManaraApp({super.key});

  /// Shows in-app prayer alerts above whichever page is open.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    // Prayer times and alerts live above the router: the home page and the
    // prayer section show the same state from one download, and alerts
    // fire on any page.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<PrayerTimesCubit>()..load()),
        BlocProvider(create: (_) => getIt<PrayerAlertsCubit>()..load()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          themeMode: ThemeMode.light,
          routerConfig: appRouter,
          scaffoldMessengerKey: messengerKey,
          // Arabic-only app: a fixed `ar` locale makes the whole UI RTL.
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => PrayerAlertScheduler(
            notifier: getIt<AlertNotifier>(),
            messengerKey: messengerKey,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
