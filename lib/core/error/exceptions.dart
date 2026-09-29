/// Exceptions thrown by the data layer and mapped to `Failure`s in repositories.
class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'تعذّر الاتصال بالإنترنت']);

  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'حدث خطأ في التخزين المحلي']);

  final String message;
}
