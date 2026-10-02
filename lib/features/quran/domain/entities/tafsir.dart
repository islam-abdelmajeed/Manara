import 'package:equatable/equatable.dart';
import 'package:manara/features/quran/domain/entities/ayah.dart';

/// Tafsir books offered in the reader. The order is the menu order.
enum TafsirSource {
  mukhtasar(
    label: 'المختصر',
    reference: 'المختصر في تفسير القرآن الكريم - مركز تفسير للدراسات القرآنية',
  ),
  ibnKathir(label: 'ابن كثير', reference: 'تفسير القرآن العظيم - ابن كثير');

  const TafsirSource({required this.label, required this.reference});

  /// Short name for the menu and the reader header.
  final String label;

  /// Full title shown as the source under the tafsir.
  final String reference;
}

/// The tafsir of one ayah, as published by the source.
class AyahTafsir extends Equatable {
  const AyahTafsir({required this.ayahKey, required this.paragraphs});

  /// `surah:ayah`, e.g. `2:6`.
  final String ayahKey;
  final List<String> paragraphs;

  @override
  List<Object?> get props => [ayahKey, paragraphs];
}

/// Consecutive ayahs that share one tafsir text.
class TafsirSection extends Equatable {
  const TafsirSection({required this.ayahs, required this.paragraphs});

  final List<Ayah> ayahs;

  /// Empty when the source has no tafsir for these ayahs.
  final List<String> paragraphs;

  /// Pairs [ayahs] with their [tafsirs]. Sources explain some ayahs
  /// together by repeating the same text on each of them, so neighbours
  /// with identical text are merged and the text is shown once.
  static List<TafsirSection> group(List<Ayah> ayahs, List<AyahTafsir> tafsirs) {
    final byKey = {for (final t in tafsirs) t.ayahKey: t.paragraphs};
    final sections = <TafsirSection>[];

    for (final ayah in ayahs) {
      final paragraphs = byKey[ayah.key] ?? const <String>[];
      final last = sections.isEmpty ? null : sections.last;
      final sameAsLast =
          last != null &&
          paragraphs.isNotEmpty &&
          last.ayahs.last.surahNumber == ayah.surahNumber &&
          _listEquals(last.paragraphs, paragraphs);

      if (sameAsLast) {
        sections[sections.length - 1] = TafsirSection(
          ayahs: [...last.ayahs, ayah],
          paragraphs: last.paragraphs,
        );
      } else {
        sections.add(TafsirSection(ayahs: [ayah], paragraphs: paragraphs));
      }
    }
    return sections;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [ayahs, paragraphs];
}
