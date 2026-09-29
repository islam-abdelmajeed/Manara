import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside the app theme with the Arabic (RTL) locale.
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: Center(child: widget)),
      ),
    );
  }

  /// Pumps a full-screen [widget] (one that has its own Scaffold) at the
  /// given logical [size].
  Future<void> pumpScreen(Widget widget, {Size size = const Size(390, 844)}) {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
    return pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: widget,
      ),
    );
  }
}
