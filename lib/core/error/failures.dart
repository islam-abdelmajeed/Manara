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

/// Why the device's location could not be read.
enum LocationProblem {
  /// Location services are off on the device.
  serviceOff,

  /// The user declined; the app may ask again.
  denied,

  /// Blocked in the system settings; the app can't ask again.
  deniedForever,

  /// No position came (timeout, no signal, …).
  unavailable,
}

final class LocationFailure extends Failure {
  const LocationFailure(this.problem) : super('');

  final LocationProblem problem;

  @override
  String get message => switch (problem) {
    LocationProblem.serviceOff =>
      'خدمة الموقع مغلقة في جهازك؛ فعّلها ثم حاول مرة أخرى، أو اختر مدينتك '
          'من القائمة.',
    LocationProblem.denied =>
      'لم يُسمح بمعرفة موقعك؛ يمكنك اختيار مدينتك من القائمة.',
    LocationProblem.deniedForever =>
      'الوصول إلى الموقع محجوب من إعدادات الجهاز؛ اسمح به من هناك، أو اختر '
          'مدينتك من القائمة.',
    LocationProblem.unavailable =>
      'تعذّر تحديد موقعك الآن؛ حاول مرة أخرى أو اختر مدينتك من القائمة.',
  };

  /// Only the system settings can fix it.
  bool get needsSettings =>
      problem == LocationProblem.serviceOff ||
      problem == LocationProblem.deniedForever;

  @override
  List<Object?> get props => [problem];
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'حدث خطأ غير متوقع']);
}
