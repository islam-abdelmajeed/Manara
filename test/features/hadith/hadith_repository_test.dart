import 'package:flutter_test/flutter_test.dart';
import 'package:manara/features/hadith/data/datasources/daily_hadith_local_data_source.dart';
import 'package:manara/features/hadith/data/repositories/hadith_repository_impl.dart';
import 'package:manara/features/hadith/domain/entities/hadith.dart';

void main() {
  const repository = HadithRepositoryImpl(DailyHadithLocalDataSourceImpl());

  Future<Hadith> on(DateTime date) async =>
      (await repository.getHadithOfTheDay(date)).toNullable()!;

  test('the same day always gets the same hadith', () async {
    expect(
      await on(DateTime(2026, 9, 29, 0, 5)),
      await on(DateTime(2026, 9, 29, 23, 55)),
    );
  });

  test('consecutive days get different hadiths', () async {
    expect(
      await on(DateTime(2026, 9, 29)),
      isNot(await on(DateTime(2026, 9, 30))),
    );
  });

  test('the list cycles through every hadith', () async {
    final all = const DailyHadithLocalDataSourceImpl().all();
    final seen = <Hadith>{
      for (var i = 0; i < all.length; i++)
        await on(DateTime(2026, 1, 1).add(Duration(days: i))),
    };
    expect(seen, all.toSet());
  });

  test('every hadith names its source', () {
    for (final hadith in const DailyHadithLocalDataSourceImpl().all()) {
      expect(hadith.text, isNotEmpty);
      expect(hadith.source, anyOf(startsWith('رواه'), 'متفق عليه'));
    }
  });
}
