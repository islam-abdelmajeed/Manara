import 'package:injectable/injectable.dart';
import 'package:manara/core/error/guard.dart';
import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/data/datasources/quran_remote_data_source.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:manara/features/quran/domain/repositories/quran_repository.dart';

@LazySingleton(as: QuranRepository)
class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl(this._remote);

  final QuranRemoteDataSource _remote;

  // Surah list and visited pages never change, so they are cached for the
  // lifetime of the app.
  List<Surah>? _surahs;
  final Map<int, MushafPage> _pages = {};

  @override
  ResultFuture<List<Surah>> getSurahs() {
    return guard(() async => _surahs ??= await _remote.fetchSurahs());
  }

  @override
  ResultFuture<MushafPage> getPage(int pageNumber) {
    return guard(() async {
      final cached = _pages[pageNumber];
      if (cached != null) return cached;
      return _pages[pageNumber] = await _remote.fetchPage(pageNumber);
    });
  }
}
