import 'package:injectable/injectable.dart';
import 'package:manara/features/quran/domain/entities/reader_progress.dart';
import 'package:manara/features/quran/domain/entities/reader_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ReaderPreferencesLocalDataSource {
  ReaderSettings readSettings();

  Future<void> writeSettings(ReaderSettings settings);

  ReaderProgress readProgress();

  Future<void> writeProgress(ReaderProgress progress);
}

@LazySingleton(as: ReaderPreferencesLocalDataSource)
class ReaderPreferencesLocalDataSourceImpl
    implements ReaderPreferencesLocalDataSource {
  const ReaderPreferencesLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _font = 'reader.font';
  static const _fontScale = 'reader.fontScale';
  static const _lineSpacing = 'reader.lineSpacing';
  static const _textColor = 'reader.textColor';
  static const _backgroundColor = 'reader.backgroundColor';
  static const _stopMarks = 'reader.stopMarks';
  static const _tashkeel = 'reader.tashkeel';
  static const _highlight = 'reader.highlight';
  static const _lastPage = 'reader.lastPage';
  static const _recent = 'reader.recent';
  static const _bookmarks = 'reader.bookmarks';
  static const _days = 'reader.days';

  @override
  ReaderSettings readSettings() {
    const defaults = ReaderSettings();
    return ReaderSettings(
      font: _enumAt(MushafFont.values, _prefs.getInt(_font), defaults.font),
      fontScale: (_prefs.getDouble(_fontScale) ?? defaults.fontScale).clamp(
        ReaderSettings.minFontScale,
        ReaderSettings.maxFontScale,
      ),
      lineSpacing: _enumAt(
        LineSpacing.values,
        _prefs.getInt(_lineSpacing),
        defaults.lineSpacing,
      ),
      textColorIndex: _prefs.getInt(_textColor) ?? defaults.textColorIndex,
      backgroundColorIndex:
          _prefs.getInt(_backgroundColor) ?? defaults.backgroundColorIndex,
      showStopMarks: _prefs.getBool(_stopMarks) ?? defaults.showStopMarks,
      showTashkeel: _prefs.getBool(_tashkeel) ?? defaults.showTashkeel,
      highlightWhilePlaying:
          _prefs.getBool(_highlight) ?? defaults.highlightWhilePlaying,
    );
  }

  @override
  Future<void> writeSettings(ReaderSettings s) async {
    await Future.wait([
      _prefs.setInt(_font, s.font.index),
      _prefs.setDouble(_fontScale, s.fontScale),
      _prefs.setInt(_lineSpacing, s.lineSpacing.index),
      _prefs.setInt(_textColor, s.textColorIndex),
      _prefs.setInt(_backgroundColor, s.backgroundColorIndex),
      _prefs.setBool(_stopMarks, s.showStopMarks),
      _prefs.setBool(_tashkeel, s.showTashkeel),
      _prefs.setBool(_highlight, s.highlightWhilePlaying),
    ]);
  }

  @override
  ReaderProgress readProgress() {
    return ReaderProgress(
      lastPage: _prefs.getInt(_lastPage) ?? 1,
      recentPages: _intList(_recent),
      bookmarkedPages: _intList(_bookmarks),
      readingDays: [
        for (final raw in _prefs.getStringList(_days) ?? const <String>[])
          ?DateTime.tryParse(raw),
      ],
    );
  }

  @override
  Future<void> writeProgress(ReaderProgress p) async {
    await Future.wait([
      _prefs.setInt(_lastPage, p.lastPage),
      _prefs.setStringList(_recent, [for (final n in p.recentPages) '$n']),
      _prefs.setStringList(_bookmarks, [
        for (final n in p.bookmarkedPages) '$n',
      ]),
      _prefs.setStringList(_days, [for (final d in p.readingDays) _date(d)]),
    ]);
  }

  /// `yyyy-MM-dd`, which [DateTime.tryParse] reads back as local midnight.
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  List<int> _intList(String key) {
    return [
      for (final raw in _prefs.getStringList(key) ?? const <String>[])
        ?int.tryParse(raw),
    ];
  }

  T _enumAt<T>(List<T> values, int? index, T fallback) {
    if (index == null || index < 0 || index >= values.length) return fallback;
    return values[index];
  }
}
