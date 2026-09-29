import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';

abstract interface class QuranRepository {
  ResultFuture<List<Surah>> getSurahs();

  ResultFuture<MushafPage> getPage(int pageNumber);
}
