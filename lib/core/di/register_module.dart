import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:manara/core/network/dio_factory.dart';

/// Third-party dependencies that can't be annotated directly.
@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => DioFactory.create();
}
