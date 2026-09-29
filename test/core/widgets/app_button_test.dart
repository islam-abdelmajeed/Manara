import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('primary renders label and calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AppButton(label: 'إنشاء الغرفة', onPressed: () => taps++),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.text('إنشاء الغرفة'));
      expect(taps, 1);
    });

    testWidgets('primary is 48 high with the primary fill', (tester) async {
      await tester.pumpApp(AppButton(label: 'حفظ', onPressed: () {}));

      expect(tester.getSize(find.byType(FilledButton)).height, 48);
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, AppColors.primary);
    });

    testWidgets('secondary uses a white fill', (tester) async {
      await tester.pumpApp(
        AppButton.secondary(label: 'إلغاء', onPressed: () {}),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, AppColors.surface);
    });

    testWidgets('loading shows a spinner and ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AppButton(label: 'حفظ', isLoading: true, onPressed: () => taps++),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('حفظ'), findsNothing);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('expand stretches to the available width', (tester) async {
      await tester.pumpApp(
        SizedBox(
          width: 300,
          child: AppButton(label: 'حفظ', expand: true, onPressed: () {}),
        ),
      );

      expect(tester.getSize(find.byType(FilledButton)).width, 300);
    });
  });
}
