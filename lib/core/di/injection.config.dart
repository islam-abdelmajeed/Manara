// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:flutter/services.dart' as _i281;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:manara/core/di/register_module.dart' as _i530;
import 'package:manara/features/hadith/data/datasources/daily_hadith_local_data_source.dart'
    as _i970;
import 'package:manara/features/hadith/data/repositories/hadith_repository_impl.dart'
    as _i949;
import 'package:manara/features/hadith/domain/repositories/hadith_repository.dart'
    as _i146;
import 'package:manara/features/hadith/domain/usecases/get_hadith_of_the_day.dart'
    as _i1;
import 'package:manara/features/home/presentation/cubit/home_cubit.dart'
    as _i757;
import 'package:manara/features/prayer/data/datasources/city_catalog_data_source.dart'
    as _i695;
import 'package:manara/features/prayer/data/datasources/prayer_local_data_source.dart'
    as _i524;
import 'package:manara/features/prayer/data/datasources/prayer_times_remote_data_source.dart'
    as _i945;
import 'package:manara/features/prayer/data/repositories/city_repository_impl.dart'
    as _i1056;
import 'package:manara/features/prayer/data/repositories/prayer_preferences_repository_impl.dart'
    as _i858;
import 'package:manara/features/prayer/data/repositories/prayer_times_repository_impl.dart'
    as _i598;
import 'package:manara/features/prayer/domain/repositories/city_repository.dart'
    as _i591;
import 'package:manara/features/prayer/domain/repositories/prayer_preferences_repository.dart'
    as _i497;
import 'package:manara/features/prayer/domain/repositories/prayer_times_repository.dart'
    as _i742;
import 'package:manara/features/prayer/domain/usecases/city_usecases.dart'
    as _i990;
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart'
    as _i462;
import 'package:manara/features/prayer/domain/usecases/prayer_preferences_usecases.dart'
    as _i448;
import 'package:manara/features/prayer/presentation/cubit/city_search_cubit.dart'
    as _i370;
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart'
    as _i253;
import 'package:manara/features/prayer/presentation/cubit/prayer_alerts_cubit.dart'
    as _i177;
import 'package:manara/features/prayer/presentation/cubit/prayer_month_cubit.dart'
    as _i943;
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart'
    as _i258;
import 'package:manara/features/quran/data/datasources/quran_remote_data_source.dart'
    as _i359;
import 'package:manara/features/quran/data/datasources/reader_preferences_local_data_source.dart'
    as _i733;
import 'package:manara/features/quran/data/datasources/tafsir_remote_data_source.dart'
    as _i227;
import 'package:manara/features/quran/data/repositories/quran_repository_impl.dart'
    as _i426;
import 'package:manara/features/quran/data/repositories/reader_preferences_repository_impl.dart'
    as _i395;
import 'package:manara/features/quran/data/repositories/tafsir_repository_impl.dart'
    as _i390;
import 'package:manara/features/quran/domain/repositories/quran_repository.dart'
    as _i119;
import 'package:manara/features/quran/domain/repositories/reader_preferences_repository.dart'
    as _i845;
import 'package:manara/features/quran/domain/repositories/tafsir_repository.dart'
    as _i483;
import 'package:manara/features/quran/domain/usecases/get_mushaf_page.dart'
    as _i470;
import 'package:manara/features/quran/domain/usecases/get_surahs.dart' as _i73;
import 'package:manara/features/quran/domain/usecases/reader_progress_usecases.dart'
    as _i147;
import 'package:manara/features/quran/domain/usecases/reader_settings_usecases.dart'
    as _i551;
import 'package:manara/features/quran/domain/usecases/tafsir_usecases.dart'
    as _i568;
import 'package:manara/features/quran/presentation/cubit/quran_index_cubit.dart'
    as _i509;
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart'
    as _i1056;
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart'
    as _i917;
import 'package:manara/features/quran/presentation/cubit/tafsir_cubit.dart'
    as _i132;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i281.AssetBundle>(() => registerModule.assetBundle);
    gh.lazySingleton<_i359.QuranRemoteDataSource>(
      () => _i359.QuranRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i970.DailyHadithLocalDataSource>(
      () => const _i970.DailyHadithLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i945.PrayerTimesRemoteDataSource>(
      () => _i945.PrayerTimesRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i227.TafsirRemoteDataSource>(
      () => _i227.TafsirRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i146.HadithRepository>(
      () => _i949.HadithRepositoryImpl(gh<_i970.DailyHadithLocalDataSource>()),
    );
    gh.lazySingleton<_i177.AlertNotifier>(
      () => const _i177.BrowserAlertNotifier(),
    );
    gh.factory<_i1.GetHadithOfTheDay>(
      () => _i1.GetHadithOfTheDay(gh<_i146.HadithRepository>()),
    );
    gh.lazySingleton<_i733.ReaderPreferencesLocalDataSource>(
      () => _i733.ReaderPreferencesLocalDataSourceImpl(
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i483.TafsirRepository>(
      () => _i390.TafsirRepositoryImpl(gh<_i227.TafsirRemoteDataSource>()),
    );
    gh.lazySingleton<_i695.CityCatalogDataSource>(
      () => _i695.CityCatalogDataSourceImpl(gh<_i281.AssetBundle>()),
    );
    gh.lazySingleton<_i524.PrayerLocalDataSource>(
      () => _i524.PrayerLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i119.QuranRepository>(
      () => _i426.QuranRepositoryImpl(gh<_i359.QuranRemoteDataSource>()),
    );
    gh.lazySingleton<_i742.PrayerTimesRepository>(
      () => _i598.PrayerTimesRepositoryImpl(
        gh<_i945.PrayerTimesRemoteDataSource>(),
        gh<_i524.PrayerLocalDataSource>(),
      ),
    );
    gh.factory<_i568.GetPageTafsir>(
      () => _i568.GetPageTafsir(gh<_i483.TafsirRepository>()),
    );
    gh.lazySingleton<_i845.ReaderPreferencesRepository>(
      () => _i395.ReaderPreferencesRepositoryImpl(
        gh<_i733.ReaderPreferencesLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i591.CityRepository>(
      () => _i1056.CityRepositoryImpl(gh<_i695.CityCatalogDataSource>()),
    );
    gh.factory<_i462.GetPrayerMonth>(
      () => _i462.GetPrayerMonth(gh<_i742.PrayerTimesRepository>()),
    );
    gh.factory<_i470.GetMushafPage>(
      () => _i470.GetMushafPage(gh<_i119.QuranRepository>()),
    );
    gh.factory<_i73.GetSurahs>(
      () => _i73.GetSurahs(gh<_i119.QuranRepository>()),
    );
    gh.lazySingleton<_i497.PrayerPreferencesRepository>(
      () => _i858.PrayerPreferencesRepositoryImpl(
        gh<_i524.PrayerLocalDataSource>(),
      ),
    );
    gh.factory<_i990.GetNearbyCities>(
      () => _i990.GetNearbyCities(gh<_i591.CityRepository>()),
    );
    gh.factory<_i990.SearchCities>(
      () => _i990.SearchCities(gh<_i591.CityRepository>()),
    );
    gh.factory<_i147.GetReaderProgress>(
      () => _i147.GetReaderProgress(gh<_i845.ReaderPreferencesRepository>()),
    );
    gh.factory<_i147.RecordPageVisit>(
      () => _i147.RecordPageVisit(gh<_i845.ReaderPreferencesRepository>()),
    );
    gh.factory<_i147.ToggleBookmark>(
      () => _i147.ToggleBookmark(gh<_i845.ReaderPreferencesRepository>()),
    );
    gh.factory<_i551.GetReaderSettings>(
      () => _i551.GetReaderSettings(gh<_i845.ReaderPreferencesRepository>()),
    );
    gh.factory<_i551.SaveReaderSettings>(
      () => _i551.SaveReaderSettings(gh<_i845.ReaderPreferencesRepository>()),
    );
    gh.factory<_i568.GetTafsirSource>(
      () => _i568.GetTafsirSource(gh<_i845.ReaderPreferencesRepository>()),
    );
    gh.factory<_i568.SaveTafsirSource>(
      () => _i568.SaveTafsirSource(gh<_i845.ReaderPreferencesRepository>()),
    );
    gh.factory<_i253.NearbyCitiesCubit>(
      () => _i253.NearbyCitiesCubit(gh<_i990.GetNearbyCities>()),
    );
    gh.factory<_i462.GetPrayerTimes>(
      () => _i462.GetPrayerTimes(gh<_i462.GetPrayerMonth>()),
    );
    gh.factory<_i943.PrayerMonthCubit>(
      () => _i943.PrayerMonthCubit(gh<_i462.GetPrayerMonth>()),
    );
    gh.factory<_i757.HomeCubit>(
      () => _i757.HomeCubit(
        gh<_i1.GetHadithOfTheDay>(),
        gh<_i147.GetReaderProgress>(),
      ),
    );
    gh.factory<_i370.CitySearchCubit>(
      () => _i370.CitySearchCubit(gh<_i990.SearchCities>()),
    );
    gh.factory<_i917.ReaderSettingsCubit>(
      () => _i917.ReaderSettingsCubit(
        gh<_i551.GetReaderSettings>(),
        gh<_i551.SaveReaderSettings>(),
      ),
    );
    gh.factory<_i1056.QuranReaderCubit>(
      () => _i1056.QuranReaderCubit(
        gh<_i73.GetSurahs>(),
        gh<_i470.GetMushafPage>(),
        gh<_i147.GetReaderProgress>(),
        gh<_i147.RecordPageVisit>(),
        gh<_i147.ToggleBookmark>(),
      ),
    );
    gh.factory<_i509.QuranIndexCubit>(
      () => _i509.QuranIndexCubit(
        gh<_i73.GetSurahs>(),
        gh<_i147.GetReaderProgress>(),
        gh<_i470.GetMushafPage>(),
      ),
    );
    gh.factory<_i132.TafsirCubit>(
      () => _i132.TafsirCubit(
        gh<_i568.GetPageTafsir>(),
        gh<_i568.GetTafsirSource>(),
        gh<_i568.SaveTafsirSource>(),
      ),
    );
    gh.factory<_i448.GetPrayerLocation>(
      () => _i448.GetPrayerLocation(gh<_i497.PrayerPreferencesRepository>()),
    );
    gh.factory<_i448.SavePrayerLocation>(
      () => _i448.SavePrayerLocation(gh<_i497.PrayerPreferencesRepository>()),
    );
    gh.factory<_i448.GetPrayerSettings>(
      () => _i448.GetPrayerSettings(gh<_i497.PrayerPreferencesRepository>()),
    );
    gh.factory<_i448.SavePrayerSettings>(
      () => _i448.SavePrayerSettings(gh<_i497.PrayerPreferencesRepository>()),
    );
    gh.factory<_i448.GetAlertSettings>(
      () => _i448.GetAlertSettings(gh<_i497.PrayerPreferencesRepository>()),
    );
    gh.factory<_i448.SaveAlertSettings>(
      () => _i448.SaveAlertSettings(gh<_i497.PrayerPreferencesRepository>()),
    );
    gh.factory<_i258.PrayerTimesCubit>(
      () => _i258.PrayerTimesCubit(
        gh<_i462.GetPrayerTimes>(),
        gh<_i448.GetPrayerLocation>(),
        gh<_i448.GetPrayerSettings>(),
        gh<_i448.SavePrayerLocation>(),
        gh<_i448.SavePrayerSettings>(),
      ),
    );
    gh.factory<_i177.PrayerAlertsCubit>(
      () => _i177.PrayerAlertsCubit(
        gh<_i448.GetAlertSettings>(),
        gh<_i448.SaveAlertSettings>(),
        gh<_i177.AlertNotifier>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i530.RegisterModule {}
