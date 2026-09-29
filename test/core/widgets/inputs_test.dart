import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppTextField', () {
    testWidgets('shows the label and reports typed text', (tester) async {
      String? value;
      await tester.pumpApp(
        SizedBox(
          width: 300,
          child: AppTextField(label: 'اسم الغرفة', onChanged: (v) => value = v),
        ),
      );

      expect(find.text('اسم الغرفة'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'مراجعة سورة الكهف');
      expect(value, 'مراجعة سورة الكهف');
    });
  });

  group('AppSearchField', () {
    testWidgets('shows the hint and a search icon', (tester) async {
      await tester.pumpApp(
        const SizedBox(
          width: 320,
          child: AppSearchField(hint: 'ابحث عن سورة أو آية...'),
        ),
      );

      expect(find.text('ابحث عن سورة أو آية...'), findsOneWidget);
      expect(find.byType(AppIcon), findsOneWidget);
      expect(tester.getSize(find.byType(AppSearchField)).height, 44);
    });
  });

  group('AppToggleTile', () {
    testWidgets('tapping the tile toggles the value', (tester) async {
      var value = true;
      await tester.pumpApp(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 240,
            child: AppToggleTile(
              label: 'السماح بطلب الدور',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );

      await tester.tap(find.text('السماح بطلب الدور'));
      await tester.pumpAndSettle();
      expect(value, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });
  });
}
