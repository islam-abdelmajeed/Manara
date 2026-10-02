import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/home/presentation/widgets/treasures_section.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<void> pumpAtWidth(WidgetTester tester, double width) {
    return tester.pumpApp(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(width, 800)),
          child: const SizedBox(
            width: 390,
            child: TreasuresSection(sidePadding: 16),
          ),
        ),
      ),
    );
  }

  // Android builds the first frame before the window size is known.
  testWidgets('builds without errors at width 0', (tester) async {
    await pumpAtWidth(tester, 0);

    expect(tester.takeException(), isNull);
    expect(find.byType(TreasuresSection), findsOneWidget);
  });

  testWidgets('lays out once the real width arrives', (tester) async {
    await pumpAtWidth(tester, 0);
    await pumpAtWidth(tester, 390);

    expect(tester.takeException(), isNull);
    expect(find.text('كنوز منارة'), findsOneWidget);
    // 390 - 16 = 374 → 85% = 317.9 wide, kept at the 568×383 ratio.
    final banner = tester.getSize(find.byType(ListView));
    expect(banner.height, closeTo(317.9 * 383 / 568, 0.5));
  });
}
