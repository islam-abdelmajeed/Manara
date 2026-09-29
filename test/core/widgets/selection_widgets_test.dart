import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

Color? _materialColor(WidgetTester tester, Finder of) {
  return tester
      .widget<Material>(
        find.descendant(of: of, matching: find.byType(Material)).first,
      )
      .color;
}

void main() {
  group('AppFilterChip', () {
    testWidgets('selected chip uses the primary fill', (tester) async {
      await tester.pumpApp(
        AppFilterChip(label: 'الكل', selected: true, onTap: () {}),
      );

      expect(
        _materialColor(tester, find.byType(AppFilterChip)),
        AppColors.primary,
      );
      expect(tester.getSize(find.byType(AppFilterChip)).height, 44);
    });

    testWidgets('unselected chip uses the background fill', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AppFilterChip(label: 'مراجعة', selected: false, onTap: () => taps++),
      );

      expect(
        _materialColor(tester, find.byType(AppFilterChip)),
        AppColors.background,
      );
      await tester.tap(find.text('مراجعة'));
      expect(taps, 1);
    });
  });

  group('SelectionCard', () {
    testWidgets('selected card uses the muted surface', (tester) async {
      await tester.pumpApp(
        SelectionCard(
          title: 'مميزة',
          subtitle: 'للأعضاء المحددين فقط',
          selected: true,
          onTap: () {},
        ),
      );

      expect(find.text('للأعضاء المحددين فقط'), findsOneWidget);
      expect(
        _materialColor(tester, find.byType(SelectionCard)),
        AppColors.surfaceMuted,
      );
    });

    testWidgets('unselected card uses the plain surface', (tester) async {
      await tester.pumpApp(
        SelectionCard(title: 'عامة', selected: false, onTap: () {}),
      );

      expect(
        _materialColor(tester, find.byType(SelectionCard)),
        AppColors.surface,
      );
    });
  });

  group('StatusBadge', () {
    testWidgets('live badge shows "مباشر" in green', (tester) async {
      await tester.pumpApp(const StatusBadge(status: RoomStatus.live));

      final text = tester.widget<Text>(find.text('مباشر'));
      expect(text.style?.color, AppColors.liveForeground);
    });

    testWidgets('ended badge shows "انتهت"', (tester) async {
      await tester.pumpApp(const StatusBadge(status: RoomStatus.ended));

      expect(find.text('انتهت'), findsOneWidget);
    });
  });
}
