import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:manara/core/theme/theme.dart';
import 'package:manara/features/quran/domain/entities/ayah.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/presentation/utils/quran_text_formatter.dart';
import 'package:manara/features/quran/presentation/utils/reader_palette.dart';
import 'package:manara/features/quran/presentation/widgets/surah_banner.dart';

/// Renders the ayahs of a [MushafPage] as flowing, justified Quran text.
///
/// Tapping an ayah reports its key; the ayah with [selectedAyahKey] is
/// highlighted.
class MushafText extends StatefulWidget {
  const MushafText({
    required this.page,
    required this.settings,
    required this.baseFontSize,
    required this.surahs,
    required this.onAyahTap,
    this.selectedAyahKey,
    super.key,
  });

  final MushafPage page;
  final ReaderSettings settings;

  /// Font size before the user's scale is applied.
  final double baseFontSize;
  final List<Surah> surahs;
  final String? selectedAyahKey;
  final ValueChanged<String> onAyahTap;

  @override
  State<MushafText> createState() => _MushafTextState();
}

class _MushafTextState extends State<MushafText> {
  final Map<String, TapGestureRecognizer> _recognizers = {};

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(String key) {
    return _recognizers.putIfAbsent(
      key,
      () => TapGestureRecognizer()..onTap = () => widget.onAyahTap(key),
    );
  }

  String _surahName(int id) {
    for (final surah in widget.surahs) {
      if (surah.id == id) return surah.nameArabic;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final textStyle = AppTypography.quran.copyWith(
      fontSize: widget.baseFontSize * settings.fontScale,
      height: settings.lineSpacing.height,
      color: ReaderPalette.text(settings.textColorIndex),
    );

    final children = <Widget>[];
    var buffer = <Ayah>[];

    void flush() {
      if (buffer.isEmpty) return;
      children.add(_buildParagraph(buffer, textStyle));
      buffer = <Ayah>[];
    }

    for (final ayah in widget.page.ayahs) {
      if (ayah.number == 1) {
        flush();
        children.add(
          SurahBanner(
            surahNumber: ayah.surahNumber,
            name: _surahName(ayah.surahNumber),
            style: textStyle,
          ),
        );
      }
      buffer.add(ayah);
    }
    flush();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildParagraph(List<Ayah> ayahs, TextStyle style) {
    final settings = widget.settings;
    final selected = widget.selectedAyahKey;

    return Text.rich(
      TextSpan(
        children: [
          for (final ayah in ayahs)
            TextSpan(
              text:
                  '${QuranTextFormatter.format(ayah.text, showStopMarks: settings.showStopMarks, showTashkeel: settings.showTashkeel)} '
                  '${QuranTextFormatter.ayahEndMarker(ayah.number)} ',
              recognizer: _recognizerFor(ayah.key),
              style: ayah.key == selected
                  ? style.copyWith(backgroundColor: AppColors.ayahHighlight)
                  : null,
            ),
        ],
      ),
      style: style,
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
}
