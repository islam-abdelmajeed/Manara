import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';

import '../../../helpers/quran_fixtures.dart';

AyahTafsir _t(String key, List<String> paragraphs) =>
    AyahTafsir(ayahKey: key, paragraphs: paragraphs);

void main() {
  group('TafsirSection.group', () {
    test('pairs each ayah with its own tafsir', () {
      final sections = TafsirSection.group(
        [ayah(2, 6), ayah(2, 7)],
        [
          _t('2:6', ['أ']),
          _t('2:7', ['ب']),
        ],
      );

      expect(sections, hasLength(2));
      expect(sections[0].ayahs.single.key, '2:6');
      expect(sections[0].paragraphs, ['أ']);
      expect(sections[1].paragraphs, ['ب']);
    });

    test('merges neighbours explained by the same text', () {
      final sections = TafsirSection.group(
        [ayah(2, 2), ayah(2, 3), ayah(2, 4), ayah(2, 5)],
        [
          _t('2:2', ['أ']),
          _t('2:3', ['ب']),
          _t('2:4', ['ب']),
          _t('2:5', ['ج']),
        ],
      );

      expect(sections.map((s) => s.ayahs.map((a) => a.number).toList()), [
        [2],
        [3, 4],
        [5],
      ]);
      expect(sections[1].paragraphs, ['ب']);
    });

    test('never merges across surahs', () {
      final sections = TafsirSection.group(
        [ayah(1, 7), ayah(2, 1)],
        [
          _t('1:7', ['أ']),
          _t('2:1', ['أ']),
        ],
      );

      expect(sections, hasLength(2));
    });

    test('keeps ayahs without tafsir, unmerged', () {
      final sections = TafsirSection.group([ayah(2, 6), ayah(2, 7)], const []);

      expect(sections, hasLength(2));
      expect(sections.every((s) => s.paragraphs.isEmpty), isTrue);
    });
  });

  test('every source has a label and a reference', () {
    expect(TafsirSource.values.map((s) => s.label), ['المختصر', 'ابن كثير']);
    for (final source in TafsirSource.values) {
      expect(source.reference, isNotEmpty);
    }
  });
}
