import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/quran/presentation/utils/quran_labels.dart';
import 'package:manara/features/quran/presentation/utils/quran_text_formatter.dart';

import '../../../../helpers/quran_fixtures.dart';

void main() {
  group('QuranTextFormatter', () {
    const text = 'خَتَمَ ٱللَّهُ عَلَىٰ قُلُوبِهِمْ ۖ وَعَلَىٰٓ';

    test('keeps the text untouched when everything is shown', () {
      expect(
        QuranTextFormatter.format(
          text,
          showStopMarks: true,
          showTashkeel: true,
        ),
        text,
      );
    });

    test('removes waqf marks only', () {
      final result = QuranTextFormatter.format(
        text,
        showStopMarks: false,
        showTashkeel: true,
      );
      expect(result, isNot(contains('ۖ')));
      expect(result, contains('َ')); // fatha is kept
    });

    test('removes harakat when tashkeel is hidden', () {
      final result = QuranTextFormatter.format(
        text,
        showStopMarks: true,
        showTashkeel: false,
      );
      expect(result, isNot(contains('َ')));
      expect(result, isNot(contains('ّ')));
      expect(result, contains('ۖ')); // waqf mark is kept
      expect(result, contains('ختم'));
    });

    test('formats the end-of-ayah marker with Arabic digits', () {
      expect(QuranTextFormatter.ayahEndMarker(6), '﴿٦﴾');
      expect(QuranTextFormatter.ayahEndMarker(286), '﴿٢٨٦﴾');
    });
  });

  group('QuranLabels', () {
    test('uses the plural for 3 to 10 ayahs', () {
      expect(QuranLabels.ayahCount(7), '7 آيات');
      expect(QuranLabels.ayahCount(10), '10 آيات');
    });

    test('uses the singular form otherwise', () {
      expect(QuranLabels.ayahCount(11), '11 آية');
      expect(QuranLabels.ayahCount(286), '286 آية');
    });

    test('builds the header and list subtitles like Figma', () {
      expect(QuranLabels.headerSubtitle(baqarah), 'مدنية | آية 286');
      expect(QuranLabels.listSubtitle(fatiha), 'مكية – 7 آيات');
    });

    test('has a start page for each of the 30 juz', () {
      expect(QuranLabels.juzStartPages, hasLength(30));
      expect(QuranLabels.juzStartPages.first, 1);
      expect(QuranLabels.juzStartPages.last, 582);
    });
  });
}
