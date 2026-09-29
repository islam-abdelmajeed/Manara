import 'package:equatable/equatable.dart';

/// Mushaf fonts offered in settings. Only Amiri Quran is bundled for now.
enum MushafFont { amiri }

enum LineSpacing {
  normal(1.9),
  medium(2.3),
  large(2.7);

  const LineSpacing(this.height);

  /// Line height as a multiple of the font size (Figma default is ~2.7).
  final double height;
}

class ReaderSettings extends Equatable {
  const ReaderSettings({
    this.font = MushafFont.amiri,
    this.fontScale = 1,
    this.lineSpacing = LineSpacing.large,
    this.textColorIndex = 0,
    this.backgroundColorIndex = 0,
    this.showStopMarks = true,
    this.showTashkeel = true,
    this.highlightWhilePlaying = true,
  });

  static const double minFontScale = 0.7;
  static const double maxFontScale = 1.5;

  final MushafFont font;

  /// Multiplier applied to the responsive base font size.
  final double fontScale;
  final LineSpacing lineSpacing;

  /// Index into the reader text color palette.
  final int textColorIndex;

  /// Index into the reader background color palette.
  final int backgroundColorIndex;
  final bool showStopMarks;
  final bool showTashkeel;
  final bool highlightWhilePlaying;

  ReaderSettings copyWith({
    MushafFont? font,
    double? fontScale,
    LineSpacing? lineSpacing,
    int? textColorIndex,
    int? backgroundColorIndex,
    bool? showStopMarks,
    bool? showTashkeel,
    bool? highlightWhilePlaying,
  }) {
    return ReaderSettings(
      font: font ?? this.font,
      fontScale: (fontScale ?? this.fontScale).clamp(
        minFontScale,
        maxFontScale,
      ),
      lineSpacing: lineSpacing ?? this.lineSpacing,
      textColorIndex: textColorIndex ?? this.textColorIndex,
      backgroundColorIndex: backgroundColorIndex ?? this.backgroundColorIndex,
      showStopMarks: showStopMarks ?? this.showStopMarks,
      showTashkeel: showTashkeel ?? this.showTashkeel,
      highlightWhilePlaying:
          highlightWhilePlaying ?? this.highlightWhilePlaying,
    );
  }

  @override
  List<Object?> get props => [
    font,
    fontScale,
    lineSpacing,
    textColorIndex,
    backgroundColorIndex,
    showStopMarks,
    showTashkeel,
    highlightWhilePlaying,
  ];
}
