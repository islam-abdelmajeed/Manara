import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/network/dio_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Third-party dependencies that can't be annotated directly.
@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => DioFactory.create();

  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  /// Bundled data files (e.g. the city list).
  @lazySingleton
  AssetBundle get assetBundle => rootBundle;
}
