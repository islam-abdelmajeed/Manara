import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

/// Tests render with the Ahem font by default, which is far wider than
/// Tajawal, so layout assertions need the real font.
Future<void> _loadTajawal() async {
  final loader = FontLoader('Tajawal');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Tajawal-$weight.ttf'));
  }
  await loader.load();
}

void main() {
  const items = [
    AppTabItem(label: 'قراءة'),
    AppTabItem(label: 'تفسير'),
    AppTabItem(label: 'ترجمة', enabled: false),
  ];

  testWidgets('shows every tab and reports taps', (tester) async {
    int? tapped;
    await tester.pumpApp(
      AppTabBar(items: items, selectedIndex: 0, onChanged: (i) => tapped = i),
    );

    for (final item in items) {
      expect(find.text(item.label), findsOneWidget);
    }
    await tester.tap(find.text('تفسير'));
    expect(tapped, 1);
  });

  testWidgets('disabled tabs ignore taps', (tester) async {
    int? tapped;
    await tester.pumpApp(
      AppTabBar(items: items, selectedIndex: 0, onChanged: (i) => tapped = i),
    );

    await tester.tap(find.text('ترجمة'));
    expect(tapped, isNull);
  });

  testWidgets('selected tab is dark, larger and elevated', (tester) async {
    await tester.pumpApp(
      AppTabBar(items: items, selectedIndex: 1, onChanged: (_) {}),
    );
    await tester.pumpAndSettle();

    BoxDecoration decorationOf(String label) {
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return container.decoration! as BoxDecoration;
    }

    final selected = decorationOf('تفسير');
    expect(selected.color, AppColors.tabSelected);
    expect(selected.boxShadow, isNotEmpty);
    expect(decorationOf('قراءة').color, AppColors.readerBackground);
    expect(decorationOf('قراءة').boxShadow, isNull);
  });

  testWidgets('four tabs fit on one row of a 390px screen', (tester) async {
    await tester.runAsync(_loadTajawal);
    await tester.pumpScreen(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: AppTabBar(
            items: const [
              AppTabItem(label: 'قراءة'),
              AppTabItem(label: 'تفسير'),
              AppTabItem(label: 'ترجمة'),
              AppTabItem(label: 'ترتيل'),
            ],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final tops = {
      for (final label in ['قراءة', 'تفسير', 'ترجمة', 'ترتيل'])
        tester.getCenter(find.text(label)).dy.round(),
    };
    expect(tops, hasLength(1));
  });
}
