import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/presentation/widgets/mushaf_text.dart';
import 'package:manara/features/quran/presentation/widgets/page_pager.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/quran_fixtures.dart';

List<TextSpan> _ayahSpans(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('نص الآية'),
    ),
  );
  final spans = <TextSpan>[];
  rich.text.visitChildren((span) {
    if (span is TextSpan && span.recognizer != null) spans.add(span);
    return true;
  });
  return spans;
}

void main() {
  group('PagePager', () {
    testWidgets('shows a window of pages around the current one', (
      tester,
    ) async {
      await tester.pumpApp(PagePager(currentPage: 50, onPageSelected: (_) {}));

      for (final page in [46, 47, 48, 49, 50, 51, 52, 53, 54]) {
        expect(find.text('$page'), findsOneWidget);
      }
      expect(find.text('45'), findsNothing);
    });

    testWidgets('keeps the window inside the Mushaf at both ends', (
      tester,
    ) async {
      await tester.pumpApp(PagePager(currentPage: 1, onPageSelected: (_) {}));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);

      await tester.pumpApp(PagePager(currentPage: 604, onPageSelected: (_) {}));
      expect(find.text('596'), findsOneWidget);
      expect(find.text('604'), findsOneWidget);
    });

    testWidgets('the current page is the largest number', (tester) async {
      await tester.pumpApp(PagePager(currentPage: 50, onPageSelected: (_) {}));

      double sizeOf(int page) =>
          tester.widget<Text>(find.text('$page')).style!.fontSize!;

      expect(sizeOf(50), 48);
      expect(sizeOf(50), greaterThan(sizeOf(49)));
      expect(sizeOf(49), greaterThan(sizeOf(48)));
      expect(sizeOf(46), 20);
    });

    testWidgets('tapping a page reports it', (tester) async {
      int? selected;
      await tester.pumpApp(
        PagePager(currentPage: 50, onPageSelected: (p) => selected = p),
      );

      await tester.tap(find.text('52'));
      expect(selected, 52);
    });

    testWidgets('numbers ascend from left to right', (tester) async {
      await tester.pumpApp(PagePager(currentPage: 50, onPageSelected: (_) {}));

      expect(
        tester.getCenter(find.text('49')).dx,
        lessThan(tester.getCenter(find.text('51')).dx),
      );
    });

    test('exposes the visible window', () {
      expect(PagePager(currentPage: 10, onPageSelected: (_) {}).pages, [
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
      ]);
      expect(
        PagePager(currentPage: 10, radius: 2, onPageSelected: (_) {}).pages,
        hasLength(5),
      );
      expect(MushafPage.lastNumber, 604);
    });
  });

  group('MushafText', () {
    Widget build({
      ReaderSettings settings = const ReaderSettings(),
      String? selected,
      ValueChanged<String>? onTap,
      MushafPage? page,
    }) {
      return SingleChildScrollView(
        child: MushafText(
          page: page ?? pageOf(3),
          settings: settings,
          baseFontSize: 30,
          surahs: surahs,
          selectedAyahKey: selected,
          onAyahTap: onTap ?? (_) {},
        ),
      );
    }

    testWidgets('renders every ayah with its end marker', (tester) async {
      await tester.pumpApp(build());

      final text = tester
          .widget<RichText>(
            find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText().contains('نص'),
            ),
          )
          .text
          .toPlainText();
      expect(text, contains('نص الآية 1'));
      expect(text, contains('﴿١﴾'));
      expect(text, contains('﴿٣﴾'));
    });

    testWidgets('applies the size, spacing and color settings', (tester) async {
      await tester.pumpApp(
        build(
          settings: const ReaderSettings(
            fontScale: 1.5,
            lineSpacing: LineSpacing.normal,
            textColorIndex: 2,
          ),
        ),
      );

      final rich = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('نص'),
        ),
      );
      final style = rich.text.style!;
      expect(style.fontSize, 45);
      expect(style.height, LineSpacing.normal.height);
      expect(style.color, AppColors.green900);
      expect(style.fontFamily, AppTypography.quranFontFamily);
    });

    testWidgets('highlights only the selected ayah', (tester) async {
      await tester.pumpApp(build(selected: '2:2'));

      final spans = _ayahSpans(tester);
      expect(spans, hasLength(3));
      expect(spans[0].style?.backgroundColor, isNull);
      expect(spans[1].style?.backgroundColor, AppColors.ayahHighlight);
      expect(spans[2].style?.backgroundColor, isNull);
    });

    testWidgets('tapping an ayah reports its key', (tester) async {
      final tapped = <String>[];
      await tester.pumpApp(build(onTap: tapped.add));

      final spans = _ayahSpans(tester);
      (spans[2].recognizer! as TapGestureRecognizer).onTap!();

      expect(tapped, ['2:3']);
    });

    testWidgets('hides waqf marks and tashkeel on request', (tester) async {
      final page = MushafPage(
        number: 3,
        ayahs: [ayah(2, 2, text: 'خَتَمَ ۖ ٱللَّهُ')],
      );
      await tester.pumpApp(
        build(
          page: page,
          settings: const ReaderSettings(
            showStopMarks: false,
            showTashkeel: false,
          ),
        ),
      );

      final text = tester
          .widget<RichText>(
            find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText().contains('ختم'),
            ),
          )
          .text
          .toPlainText();
      expect(text, contains('ختم'));
      expect(text, isNot(contains('ۖ')));
      expect(text, isNot(contains('َ')));
    });

    testWidgets('a surah start shows a banner and the basmala', (tester) async {
      await tester.pumpApp(build(page: pageOf(2)));

      expect(find.text('سُورَةُ البقرة'), findsOneWidget);
      expect(find.textContaining('بِسْمِ ٱللَّهِ'), findsOneWidget);
    });

    testWidgets('Al-Fatiha has no separate basmala, At-Tawbah none either', (
      tester,
    ) async {
      await tester.pumpApp(build(page: pageOf(1, surah: 1)));
      expect(find.text('سُورَةُ الفاتحة'), findsOneWidget);
      expect(find.textContaining('بِسْمِ ٱللَّهِ'), findsNothing);
    });

    testWidgets('a page in the middle of a surah has no banner', (
      tester,
    ) async {
      await tester.pumpApp(build(page: pageOf(3, firstAyah: 6)));
      expect(find.textContaining('سُورَةُ'), findsNothing);
    });
  });
}
