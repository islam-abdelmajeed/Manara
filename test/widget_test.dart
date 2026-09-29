import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/app/app.dart';

void main() {
  testWidgets('app boots in Arabic RTL', (tester) async {
    await tester.pumpWidget(const ManaraApp());
    await tester.pumpAndSettle();

    expect(find.text('منارة'), findsOneWidget);
    final direction = Directionality.of(tester.element(find.text('منارة')));
    expect(direction, TextDirection.rtl);
  });
}
