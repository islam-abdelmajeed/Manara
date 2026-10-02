import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';

abstract interface class TafsirRepository {
  /// Tafsir of every ayah on [page] from [source], in Mushaf order.
  ResultFuture<List<AyahTafsir>> getPageTafsir(
    TafsirSource source,
    MushafPage page,
  );
}
