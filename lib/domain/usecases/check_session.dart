import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CheckSession {
  final AuthRepository repository;

  CheckSession(this.repository);

  Future<Either<Failure, (User?, String?)>> call() async {
    final userResult = await repository.getSavedUser();
    final tokenResult = await repository.getSavedToken();

    return userResult.fold(
      (failure) => Left(failure),
      (user) => tokenResult.fold(
        (failure) => Left(failure),
        (token) => Right((user, token)),
      ),
    );
  }
}
