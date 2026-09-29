import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/core/error/failures.dart';
import 'package:manara/features/quran/data/datasources/quran_remote_data_source.dart';
import 'package:manara/features/quran/data/models/mushaf_page_model.dart';
import 'package:manara/features/quran/data/models/surah_model.dart';
import 'package:manara/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:manara/features/quran/domain/entities/surah.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/quran_fixtures.dart';

class MockDio extends Mock implements Dio {}

class MockRemote extends Mock implements QuranRemoteDataSource {}

void main() {
  group('models', () {
    test('SurahModel parses a Quran.com chapter', () {
      final surah = SurahModel.fromJson(
        (chaptersJson()['chapters'] as List).first as Map<String, dynamic>,
      );
      expect(surah.id, 2);
      expect(surah.nameArabic, 'البقرة');
      expect(surah.revelationPlace, RevelationPlace.madinah);
      expect(surah.versesCount, 286);
      expect(surah.firstPage, 2);
      expect(surah.lastPage, 49);
    });

    test('MushafPageModel parses verses and their keys', () {
      final page = MushafPageModel.fromJson(3, versesJson());
      expect(page.number, 3);
      expect(page.ayahs.map((a) => a.key), ['2:6', '2:7']);
      expect(page.ayahs.first.pageNumber, 3);
      expect(page.firstSurahNumber, 2);
    });
  });

  group('QuranRemoteDataSourceImpl', () {
    late MockDio dio;
    late QuranRemoteDataSourceImpl source;

    setUp(() {
      dio = MockDio();
      source = QuranRemoteDataSourceImpl(dio);
    });

    Response<Map<String, dynamic>> ok(Map<String, dynamic> data) =>
        Response(requestOptions: RequestOptions(), data: data, statusCode: 200);

    test('fetchSurahs asks for Arabic names', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/chapters',
          queryParameters: {'language': 'ar'},
        ),
      ).thenAnswer((_) async => ok(chaptersJson()));

      final surahs = await source.fetchSurahs();
      expect(surahs, hasLength(2));
    });

    test('fetchPage requests the Uthmani text of the page', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/verses/by_page/3',
          queryParameters: {'fields': 'text_uthmani', 'per_page': 50},
        ),
      ).thenAnswer((_) async => ok(versesJson()));

      final page = await source.fetchPage(3);
      expect(page.ayahs, hasLength(2));
    });

    test('maps connection errors to NetworkException', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(source.fetchSurahs(), throwsA(isA<NetworkException>()));
    });

    test('maps bad responses to ServerException with the status', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(), statusCode: 500),
        ),
      );

      expect(
        source.fetchPage(1),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 500),
        ),
      );
    });
  });

  group('QuranRepositoryImpl', () {
    late MockRemote remote;
    late QuranRepositoryImpl repository;

    setUp(() {
      remote = MockRemote();
      repository = QuranRepositoryImpl(remote);
    });

    test('caches the surah list after the first load', () async {
      when(() => remote.fetchSurahs()).thenAnswer(
        (_) async => [
          SurahModel.fromJson(
            (chaptersJson()['chapters'] as List).first as Map<String, dynamic>,
          ),
        ],
      );

      await repository.getSurahs();
      final second = await repository.getSurahs();

      expect(second.isRight(), isTrue);
      verify(() => remote.fetchSurahs()).called(1);
    });

    test('caches pages by number', () async {
      when(
        () => remote.fetchPage(3),
      ).thenAnswer((_) async => MushafPageModel.fromJson(3, versesJson()));

      await repository.getPage(3);
      await repository.getPage(3);

      verify(() => remote.fetchPage(3)).called(1);
    });

    test('does not cache failures', () async {
      when(() => remote.fetchPage(3)).thenThrow(const NetworkException());

      final first = await repository.getPage(3);
      expect(
        first.swap().getOrElse((_) => throw StateError('no left')),
        isA<NetworkFailure>(),
      );

      when(
        () => remote.fetchPage(3),
      ).thenAnswer((_) async => MushafPageModel.fromJson(3, versesJson()));
      expect((await repository.getPage(3)).isRight(), isTrue);
    });

    test('maps server errors to ServerFailure', () async {
      when(
        () => remote.fetchSurahs(),
      ).thenThrow(const ServerException(message: 'x', statusCode: 503));

      final result = await repository.getSurahs();
      final failure = result.swap().getOrElse((_) => throw StateError('none'));
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
    });
  });
}
