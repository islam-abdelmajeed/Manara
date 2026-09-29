abstract final class AppConstants {
  static const String appName = 'منارة';

  /// Injected at build time:
  /// `flutter run --dart-define=BASE_URL=https://api.example.com`
  static const String baseUrl = String.fromEnvironment('BASE_URL');

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
