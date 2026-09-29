import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('RoomLinkCard', () {
    testWidgets('shows the link and fires onCopy', (tester) async {
      var copied = 0;
      await tester.pumpApp(
        SizedBox(
          width: 420,
          child: RoomLinkCard(
            title: 'رابط الغرفة',
            link: 'https://manara.app/rooms/kahf-review',
            onCopy: () => copied++,
          ),
        ),
      );

      expect(find.text('https://manara.app/rooms/kahf-review'), findsOneWidget);
      await tester.tap(find.byTooltip('نسخ الرابط'));
      expect(copied, 1);
    });
  });

  group('MemberCard', () {
    testWidgets('shows name and username', (tester) async {
      await tester.pumpApp(
        const MemberCard(name: 'أحمد محمد', username: '@ahmed123'),
      );

      expect(find.text('أحمد محمد'), findsOneWidget);
      expect(find.text('@ahmed123'), findsOneWidget);
    });
  });

  group('showAppToast', () {
    testWidgets('displays the toast message', (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppToast(context, 'تم نسخ رابط الغرفة'),
            child: const Text('نسخ'),
          ),
        ),
      );

      await tester.tap(find.text('نسخ'));
      await tester.pump();
      expect(find.text('تم نسخ رابط الغرفة'), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('shows the action and calls it', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        SizedBox(
          width: 360,
          child: SectionHeader(
            title: 'غرفي الأخيرة',
            subtitle: 'الغرف التي انضممت إليها مؤخرًا',
            actionLabel: 'عرض الكل',
            onAction: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('عرض الكل'));
      expect(taps, 1);
    });
  });
}
