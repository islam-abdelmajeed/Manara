import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/app/app.dart';
import 'package:manara/core/di/injection.dart';
import 'package:manara/core/router/app_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fonts.dart';

/// The real app and router (network calls fail in tests, which the
/// screens handle).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Fresh singletons per test: a cached future from another test's fake
  // async zone would never complete.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  Future<void> open(WidgetTester tester, String location) async {
    await loadAppFonts(tester);
    tester.view.physicalSize = const Size(1440, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ManaraApp());
    appRouter.go(location);
    // Let the city list load from the bundle.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('every prayer route opens its tab', (tester) async {
    for (final (route, title) in [
      (AppRoutes.prayer, 'مواقيت الصلاة'),
      (AppRoutes.prayerMonthly, 'جدول مواقيت الصلاة الشهري لمدينة القاهرة'),
      (AppRoutes.prayerAlerts, 'تنبيهات الصلاة'),
      (AppRoutes.prayerSettings, 'إعدادات حساب المواقيت'),
    ]) {
      await open(tester, route);
      expect(find.text(title), findsOneWidget, reason: route);
    }
  });

  testWidgets("the country's cities open listed in settings", (tester) async {
    await open(tester, AppRoutes.prayerCities(countryCode: 'EG'));

    await _pumpUntil(tester, find.text('الإسكندرية'));
    expect(find.text('الإسكندرية'), findsOneWidget);
    expect(find.text('الرياض'), findsNothing);
  });
}

/// Pumps (letting real I/O such as asset reads finish) until [finder] finds
/// something, for at most about two seconds.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}
