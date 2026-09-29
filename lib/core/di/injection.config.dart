// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
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
import 'package:manara/features/prayer/data/datasources/prayer_times_remote_data_source.dart'
    as _i945;
import 'package:manara/features/prayer/data/repositories/prayer_times_repository_impl.dart'
    as _i598;
import 'package:manara/features/prayer/domain/repositories/prayer_times_repository.dart'
    as _i742;
import 'package:manara/features/prayer/domain/usecases/get_prayer_times.dart'
    as _i462;
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart'
    as _i258;
import 'package:manara/features/quran/data/datasources/quran_remote_data_source.dart'
    as _i359;
import 'package:manara/features/quran/data/datasources/reader_preferences_local_data_source.dart'
    as _i733;
import 'package:manara/features/quran/data/repositories/quran_repository_impl.dart'
    as _i426;
import 'package:manara/features/quran/data/repositories/reader_preferences_repository_impl.dart'
    as _i395;
import 'package:manara/features/quran/domain/repositories/quran_repository.dart'
    as _i119;
import 'package:manara/features/quran/domain/repositories/reader_preferences_repository.dart'
    as _i845;
import 'package:manara/features/quran/domain/usecases/get_mushaf_page.dart'
    as _i470;
import 'package:manara/features/quran/domain/usecases/get_surahs.dart' as _i73;
import 'package:manara/features/quran/domain/usecases/reader_progress_usecases.dart'
    as _i147;
import 'package:manara/features/quran/domain/usecases/reader_settings_usecases.dart'
    as _i551;
import 'package:manara/features/quran/presentation/cubit/quran_reader_cubit.dart'
    as _i1056;
import 'package:manara/features/quran/presentation/cubit/reader_settings_cubit.dart'
    as _i917;
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
    gh.lazySingleton<_i359.QuranRemoteDataSource>(
      () => _i359.QuranRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i970.DailyHadithLocalDataSource>(
      () => const _i970.DailyHadithLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i945.PrayerTimesRemoteDataSource>(
      () => _i945.PrayerTimesRemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i146.HadithRepository>(
      () => _i949.HadithRepositoryImpl(gh<_i970.DailyHadithLocalDataSource>()),
    );
    gh.lazySingleton<_i742.PrayerTimesRepository>(
      () => _i598.PrayerTimesRepositoryImpl(
        gh<_i945.PrayerTimesRemoteDataSource>(),
      ),
    );
    gh.factory<_i1.GetHadithOfTheDay>(
      () => _i1.GetHadithOfTheDay(gh<_i146.HadithRepository>()),
    );
    gh.factory<_i462.GetPrayerTimes>(
      () => _i462.GetPrayerTimes(gh<_i742.PrayerTimesRepository>()),
    );
    gh.lazySingleton<_i733.ReaderPreferencesLocalDataSource>(
      () => _i733.ReaderPreferencesLocalDataSourceImpl(
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i119.QuranRepository>(
      () => _i426.QuranRepositoryImpl(gh<_i359.QuranRemoteDataSource>()),
    );
    gh.factory<_i258.PrayerTimesCubit>(
      () => _i258.PrayerTimesCubit(gh<_i462.GetPrayerTimes>()),
    );
    gh.lazySingleton<_i845.ReaderPreferencesRepository>(
      () => _i395.ReaderPreferencesRepositoryImpl(
        gh<_i733.ReaderPreferencesLocalDataSource>(),
      ),
    );
    gh.factory<_i470.GetMushafPage>(
      () => _i470.GetMushafPage(gh<_i119.QuranRepository>()),
    );
    gh.factory<_i73.GetSurahs>(
      () => _i73.GetSurahs(gh<_i119.QuranRepository>()),
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
    gh.factory<_i757.HomeCubit>(
      () => _i757.HomeCubit(
        gh<_i1.GetHadithOfTheDay>(),
        gh<_i147.GetReaderProgress>(),
      ),
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
    return this;
  }
}

class _$RegisterModule extends _i530.RegisterModule {}
