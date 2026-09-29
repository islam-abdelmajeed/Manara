import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manara/core/constants/app_constants.dart';
import 'package:manara/core/router/app_router.dart';
import 'package:manara/core/theme/app_theme.dart';

class ManaraApp extends StatelessWidget {
  const ManaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(design): replace designSize with the Figma mobile frame size.
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
        // Arabic-only app: a fixed `ar` locale makes the whole UI RTL.
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
