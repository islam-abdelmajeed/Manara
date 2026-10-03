import 'package:flutter_test/flutter_test.dart';
import 'package:manara/core/di/injection.dart';
import 'package:manara/features/home/presentation/cubit/home_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/city_search_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/device_location_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/nearby_cities_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_alerts_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_month_cubit.dart';
import 'package:manara/features/prayer/presentation/cubit/prayer_times_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Catches a class added without re-running build_runner: the app would
/// only fail when the screen asks for it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  test('every cubit a screen creates can be resolved', () {
    expect(getIt<HomeCubit>(), isA<HomeCubit>());
    expect(getIt<PrayerTimesCubit>(), isA<PrayerTimesCubit>());
    expect(getIt<NearbyCitiesCubit>(), isA<NearbyCitiesCubit>());
    expect(getIt<PrayerMonthCubit>(), isA<PrayerMonthCubit>());
    expect(getIt<CitySearchCubit>(), isA<CitySearchCubit>());
    expect(getIt<PrayerAlertsCubit>(), isA<PrayerAlertsCubit>());
    expect(getIt<DeviceLocationCubit>(), isA<DeviceLocationCubit>());
  });
}
