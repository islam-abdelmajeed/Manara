import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:manara/core/error/guard.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/data/datasources/tafsir_remote_data_source.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';
import 'package:manara/features/quran/domain/repositories/tafsir_repository.dart';

@LazySingleton(as: TafsirRepository)
class TafsirRepositoryImpl implements TafsirRepository {
  TafsirRepositoryImpl(this._remote);

  final TafsirRemoteDataSource _remote;

  /// Quran.com resource id of Tafsir Ibn Kathir (Arabic).
  static const int ibnKathirId = 14;

  // Published tafsir never changes, so loaded pages and surahs are cached
  // for the lifetime of the app.
  final Map<(TafsirSource, int), List<AyahTafsir>> _pages = {};

  /// Al-Mukhtasar comes per surah; requests in flight are shared so two
  /// pages of the same surah trigger one download.
  final Map<int, Future<Map<String, AyahTafsir>>> _mukhtasarSurahs = {};

  @override
  ResultFuture<List<AyahTafsir>> getPageTafsir(
    TafsirSource source,
    MushafPage page,
  ) {
    return guard(() async {
      final key = (source, page.number);
      final cached = _pages[key];
      if (cached != null) return cached;

      final tafsir = switch (source) {
        TafsirSource.mukhtasar => await _mukhtasarPage(page),
        TafsirSource.ibnKathir => await _remote.fetchQuranComPage(
          ibnKathirId,
          page.number,
        ),
      };
      return _pages[key] = tafsir;
    });
  }

  Future<List<AyahTafsir>> _mukhtasarPage(MushafPage page) async {
    final surahs = await Future.wait(
      {for (final ayah in page.ayahs) ayah.surahNumber}.map(_mukhtasarSurah),
    );
    final byKey = {for (final surah in surahs) ...surah};
    return [for (final ayah in page.ayahs) ?byKey[ayah.key]];
  }

  Future<Map<String, AyahTafsir>> _mukhtasarSurah(int surah) {
    final pending = _mukhtasarSurahs[surah];
    if (pending != null) return pending;

    final future = _remote
        .fetchMukhtasarSurah(surah)
        .then((list) => {for (final t in list) t.ayahKey: t});
    _mukhtasarSurahs[surah] = future;
    // Forget failures so the next request tries again.
    unawaited(
      future.then<void>(
        (_) {},
        // A block body: returning the removed (failed) future would rethrow.
        onError: (Object _) {
          _mukhtasarSurahs.remove(surah);
        },
      ),
    );
    return future;
  }
}
