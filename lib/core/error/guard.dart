import 'package:fpdart/fpdart.dart';
import 'package:manara/core/error/exceptions.dart';
import 'package:manara/core/error/failures.dart';

/// Runs [action] and maps data-layer exceptions to a [Failure].
Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
  try {
    return Right(await action());
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } on Exception {
    return const Left(UnexpectedFailure());
  }
}
