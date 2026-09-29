import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// Base contract for every domain use case.
abstract interface class UseCase<T, Params> {
  ResultFuture<T> call(Params params);
}

/// Use when a use case takes no parameters.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
