import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:manara/core/constants/app_constants.dart';

abstract final class DioFactory {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Accept-Language': 'ar',
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }
}
