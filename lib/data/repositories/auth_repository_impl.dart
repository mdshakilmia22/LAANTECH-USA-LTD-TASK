import 'package:fpdart/fpdart.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final (userModel, token) = await remoteDataSource.login(
        email: email,
        password: password,
      );

      await localDataSource.saveToken(token);
      await localDataSource.saveUser(userModel);

      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String username,
    required String password,
  }) async {
    try {
      final (userModel, token) = await remoteDataSource.register(
        username: username,
        password: password,
      );

      await localDataSource.saveToken(token);
      await localDataSource.saveUser(userModel);

      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final token = await localDataSource.getToken();
      if (token != null) {
        try {
          await remoteDataSource.logout(token);
        } catch (_) {}
      }
      await localDataSource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getSavedToken() async {
    try {
      final token = await localDataSource.getToken();
      return Right(token);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getSavedUser() async {
    try {
      final userModel = await localDataSource.getUser();
      return Right(userModel?.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
