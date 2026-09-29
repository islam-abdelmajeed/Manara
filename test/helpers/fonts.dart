import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts so layout in tests matches the app. Without this
/// every text renders in the test font (Ahem), which is far wider.
Future<void> loadAppFonts(WidgetTester tester) {
  return tester.runAsync(() async {
    Future<void> load(String family, List<String> files) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      return loader.load();
    }

    await load('Tajawal', [
      'Tajawal-Regular.ttf',
      'Tajawal-Medium.ttf',
      'Tajawal-Bold.ttf',
    ]);
    await load('CalSans', ['CalSans-Regular.ttf']);
    await load('AmiriQuran', ['AmiriQuran-Regular.ttf']);
  });
}
