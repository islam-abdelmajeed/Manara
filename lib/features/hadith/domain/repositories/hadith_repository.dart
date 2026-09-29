import 'package:manara/core/usecases/usecase.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';

abstract interface class HadithRepository {
  /// The hadith featured on [date]; stable for the whole day.
  ResultFuture<Hadith> getHadithOfTheDay(DateTime date);
}
