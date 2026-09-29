import 'package:equatable/equatable.dart';

/// Domain-level error returned inside `Either<Failure, T>`.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'تعذّر الاتصال بالإنترنت']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'حدث خطأ في التخزين المحلي']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'حدث خطأ غير متوقع']);
}
