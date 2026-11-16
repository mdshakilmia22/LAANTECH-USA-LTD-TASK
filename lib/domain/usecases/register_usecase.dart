import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String username,
    required String password,
  }) {
    return repository.register(username: username, password: password);
  }
}
