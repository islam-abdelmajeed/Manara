import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manara/core/router/app_routes.dart';
import 'package:manara/core/theme/app_theme.dart';
import 'package:manara/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

const _desktop = Size(1440, 900);
const _mobile = Size(390, 844);

Widget _page() => AppScaffold(
  active: NavItem.home,
  body: Center(
    child: TextButton(onPressed: () {}, child: const Text('المحتوى')),
  ),
);

Finder get _more => find.text('المزيد');

void main() {
  group('AppNavBar more menu (wide)', () {
    testWidgets('opens the panel with every group and link', (tester) async {
      await tester.pumpScreen(_page(), size: _desktop);
      expect(find.byType(MoreMenuPanel), findsNothing);

      await tester.tap(_more);
      await tester.pump();

      expect(find.byType(MoreMenuPanel), findsOneWidget);
      for (final group in moreMenuGroups) {
        expect(find.text(group.title), findsOneWidget);
        for (final link in group.links) {
          expect(find.text(link.label), findsOneWidget);
        }
      }
    });

    testWidgets('hangs the panel from the bottom of the bar', (tester) async {
      await tester.pumpScreen(_page(), size: _desktop);
      await tester.tap(_more);
      await tester.pump();

      final panel = tester.getRect(find.byType(MoreMenuPanel));
      expect(panel.top, tester.getRect(find.byType(AppNavBar)).bottom);
      expect(panel.width, _desktop.width);
      expect(panel.height, MoreMenuPanel.height);
    });

    testWidgets('the more link toggles the panel', (tester) async {
      await tester.pumpScreen(_page(), size: _desktop);
      await tester.tap(_more);
      await tester.pump();
      await tester.tap(_more);
      await tester.pump();

      expect(find.byType(MoreMenuPanel), findsNothing);
    });

    testWidgets('closes on a tap outside and on Escape', (tester) async {
      await tester.pumpScreen(_page(), size: _desktop);

      await tester.tap(_more);
      await tester.pump();
      await tester.tap(find.text('المحتوى'));
      await tester.pump();
      expect(find.byType(MoreMenuPanel), findsNothing);

      await tester.tap(_more);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(MoreMenuPanel), findsNothing);
    });

    testWidgets('a link closes the panel and says it is coming soon', (
      tester,
    ) async {
      await tester.pumpScreen(_page(), size: _desktop);
      await tester.tap(_more);
      await tester.pump();

      await tester.tap(find.text('التفسير'));
      await tester.pump();

      expect(find.byType(MoreMenuPanel), findsNothing);
      expect(find.text('قريبًا إن شاء الله'), findsOneWidget);
    });
  });

  group('AppNavDrawer more section (compact)', () {
    testWidgets('expands to list the more links', (tester) async {
      await tester.pumpScreen(_page(), size: _mobile);
      await tester.tap(find.byTooltip('القائمة'));
      await tester.pumpAndSettle();

      expect(find.text('الملف الشخصي'), findsNothing);

      await tester.tap(_more);
      await tester.pumpAndSettle();

      expect(find.text('القرآن والتعلم'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('الملف الشخصي'), 200);
      expect(find.text('الملف الشخصي'), findsOneWidget);
    });
  });

  group('active section link', () {
    Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
      tester.view.physicalSize = _desktop;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget page(String name) =>
          AppScaffold(active: NavItem.quran, body: Text(name));
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: AppRoutes.quran,
            builder: (_, _) => page('INDEX'),
            routes: [GoRoute(path: 'read', builder: (_, _) => page('READER'))],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('leads back to the section page from a sub-page', (
      tester,
    ) async {
      await pumpAt(tester, AppRoutes.quranReader);

      await tester.tap(find.text('القرآن الكريم'));
      await tester.pumpAndSettle();

      expect(find.text('INDEX'), findsOneWidget);
    });

    testWidgets('does nothing on the section page itself', (tester) async {
      final router = await pumpAt(tester, AppRoutes.quran);

      await tester.tap(find.text('القرآن الكريم'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.quran);
      expect(find.text('INDEX'), findsOneWidget);
    });
  });
}
