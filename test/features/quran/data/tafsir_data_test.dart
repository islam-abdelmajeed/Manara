import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/quran/data/datasources/tafsir_remote_data_source.dart';
import 'package:manara/features/quran/data/models/ayah_tafsir_model.dart';
import 'package:manara/features/quran/data/repositories/tafsir_repository_impl.dart';
import 'package:manara/features/quran/domain/entities/mushaf_page.dart';
import 'package:manara/features/quran/domain/entities/tafsir.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/quran_fixtures.dart';

class MockDio extends Mock implements Dio {}

class MockRemote extends Mock implements TafsirRemoteDataSource {}

List<AyahTafsir> _right(Either<Failure, List<AyahTafsir>> either) =>
    either.getOrElse((f) => throw StateError(f.message));

AyahTafsirModel _tafsir(String key, String text) =>
    AyahTafsirModel(ayahKey: key, paragraphs: [text]);

void main() {
  group('AyahTafsirModel.fromQuranCom', () {
    test('splits paragraphs and drops styling spans', () {
      final model = AyahTafsirModel.fromQuranCom({
        'verse_key': '2:2',
        'text':
            '<p><span class="arabic qpc-hafs">( ذلك الكتاب )</span></p>'
            '<p lang="ar" class="ar ">قال ابن عباس : <span class="blue">'
            'هذا الكتاب</span> .</p>',
      });

      expect(model.ayahKey, '2:2');
      expect(model.paragraphs, [
        '( ذلك الكتاب )',
        'قال ابن عباس : هذا الكتاب .',
      ]);
    });

    test('keeps text outside paragraphs and breaks on <br>', () {
      expect(AyahTafsirModel.htmlParagraphs('أولًا<br/>ثانيًا<p>ثالثًا</p>'), [
        'أولًا',
        'ثانيًا',
        'ثالثًا',
      ]);
    });

    test('decodes entities and collapses whitespace', () {
      expect(
        AyahTafsirModel.htmlParagraphs(
          '<p>  قال&nbsp;:\n &quot;نعم&quot; &amp;#1; &#1575;</p>',
        ),
        ['قال : "نعم" &#1; ا'],
      );
    });

    test('returns no paragraphs for empty text', () {
      expect(
        AyahTafsirModel.fromQuranCom({
          'verse_key': '1:1',
          'text': '<p> </p>',
        }).paragraphs,
        isEmpty,
      );
    });
  });

  group('AyahTafsirModel.fromQuranEnc', () {
    test('parses a Mukhtasar item verbatim', () {
      final model = AyahTafsirModel.fromQuranEnc(
        mukhtasarSurah2Json()['result'][0],
      );
      expect(model.ayahKey, '2:6');
      expect(model.paragraphs, [mukhtasar2v6]);
    });

    test('removes the range of ayahs explained together', () {
      final model = AyahTafsirModel.fromQuranEnc({
        'sura': '2',
        'aya': '4',
        'translation': '3 - 4 - الذين يؤمنون بالغيب',
      });
      expect(model.paragraphs, ['الذين يؤمنون بالغيب']);
    });

    test('keeps leading numbers that are not the ayah\'s range', () {
      final model = AyahTafsirModel.fromQuranEnc({
        'sura': '2',
        'aya': '9',
        'translation': '3 - 4 - نص',
      });
      expect(model.paragraphs, ['3 - 4 - نص']);
    });
  });

  group('TafsirRemoteDataSourceImpl', () {
    late MockDio dio;
    late TafsirRemoteDataSourceImpl source;

    setUp(() {
      dio = MockDio();
      source = TafsirRemoteDataSourceImpl(dio);
    });

    Response<Map<String, dynamic>> ok(Map<String, dynamic> data) =>
        Response(requestOptions: RequestOptions(), data: data, statusCode: 200);

    test('fetchQuranComPage asks Quran.com for the whole page', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/tafsirs/14/by_page/3',
          queryParameters: {'per_page': 50},
        ),
      ).thenAnswer((_) async => ok(ibnKathirPage3Json()));

      final tafsir = await source.fetchQuranComPage(14, 3);

      expect(tafsir.map((t) => t.ayahKey), ['2:6', '2:7']);
    });

    test('fetchMukhtasarSurah asks QuranEnc for the surah', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          'https://quranenc.com/api/v1/translation/sura/arabic_mokhtasar/2',
        ),
      ).thenAnswer((_) async => ok(mukhtasarSurah2Json()));

      final tafsir = await source.fetchMukhtasarSurah(2);

      expect(tafsir.map((t) => t.ayahKey), ['2:6', '2:7']);
    });

    test('maps connection errors to NetworkException', () {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(source.fetchMukhtasarSurah(1), throwsA(isA<NetworkException>()));
    });

    test('maps bad responses to ServerException', () {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(), statusCode: 404),
        ),
      );

      expect(
        source.fetchQuranComPage(14, 3),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });
  });

  group('TafsirRepositoryImpl', () {
    late MockRemote remote;
    late TafsirRepositoryImpl repository;

    final page3 = MushafPage(
      number: 3,
      ayahs: [ayah(2, 6, page: 3), ayah(2, 7, page: 3)],
    );

    setUp(() {
      remote = MockRemote();
      repository = TafsirRepositoryImpl(remote);
    });

    test('Ibn Kathir comes from Quran.com by page and is cached', () async {
      when(
        () => remote.fetchQuranComPage(14, 3),
      ).thenAnswer((_) async => [_tafsir('2:6', 'أ'), _tafsir('2:7', 'ب')]);

      final first = _right(
        await repository.getPageTafsir(TafsirSource.ibnKathir, page3),
      );
      await repository.getPageTafsir(TafsirSource.ibnKathir, page3);

      expect(first.map((t) => t.ayahKey), ['2:6', '2:7']);
      verify(() => remote.fetchQuranComPage(14, 3)).called(1);
    });

    test('Mukhtasar keeps only the page\'s ayahs of the surah', () async {
      when(() => remote.fetchMukhtasarSurah(2)).thenAnswer(
        (_) async => [
          _tafsir('2:5', 'x'),
          _tafsir('2:6', 'أ'),
          _tafsir('2:7', 'ب'),
          _tafsir('2:8', 'y'),
        ],
      );

      final tafsir = _right(
        await repository.getPageTafsir(TafsirSource.mukhtasar, page3),
      );

      expect(tafsir.map((t) => t.ayahKey), ['2:6', '2:7']);
    });

    test('Mukhtasar loads every surah on a page, in Mushaf order', () async {
      final page = MushafPage(
        number: 604,
        ayahs: [
          ayah(112, 4, page: 604),
          ayah(113, 1, page: 604),
          ayah(114, 1, page: 604),
        ],
      );
      for (final s in [112, 113, 114]) {
        when(() => remote.fetchMukhtasarSurah(s)).thenAnswer(
          (_) async => [_tafsir(s == 112 ? '112:4' : '$s:1', 'نص $s')],
        );
      }

      final tafsir = _right(
        await repository.getPageTafsir(TafsirSource.mukhtasar, page),
      );

      expect(tafsir.map((t) => t.ayahKey), ['112:4', '113:1', '114:1']);
    });

    test('two pages of one surah share a single Mukhtasar download', () async {
      final completer = Completer<List<AyahTafsirModel>>();
      when(
        () => remote.fetchMukhtasarSurah(2),
      ).thenAnswer((_) => completer.future);
      final page4 = MushafPage(number: 4, ayahs: [ayah(2, 17, page: 4)]);

      final a = repository.getPageTafsir(TafsirSource.mukhtasar, page3);
      final b = repository.getPageTafsir(TafsirSource.mukhtasar, page4);
      completer.complete([_tafsir('2:6', 'أ'), _tafsir('2:17', 'ج')]);

      expect(_right(await a).single.ayahKey, '2:6');
      expect(_right(await b).single.ayahKey, '2:17');
      verify(() => remote.fetchMukhtasarSurah(2)).called(1);
    });

    test(
      'a failed download is mapped to a Failure and retried later',
      () async {
        var calls = 0;
        when(() => remote.fetchMukhtasarSurah(2)).thenAnswer((_) async {
          if (calls++ == 0) throw const NetworkException();
          return [_tafsir('2:6', 'أ')];
        });

        final failed = await repository.getPageTafsir(
          TafsirSource.mukhtasar,
          page3,
        );
        final retried = await repository.getPageTafsir(
          TafsirSource.mukhtasar,
          page3,
        );

        expect(failed, const Left<Failure, List<AyahTafsir>>(NetworkFailure()));
        expect(_right(retried).single.ayahKey, '2:6');
      },
    );

    test('server errors become ServerFailure', () async {
      when(() => remote.fetchQuranComPage(any(), any())).thenThrow(
        const ServerException(message: 'تعذّر تحميل البيانات', statusCode: 500),
      );

      final result = await repository.getPageTafsir(
        TafsirSource.ibnKathir,
        page3,
      );

      expect(
        result.getLeft().toNullable(),
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 500),
      );
    });
  });
}
