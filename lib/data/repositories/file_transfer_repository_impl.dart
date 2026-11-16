import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/repositories/file_transfer_repository.dart';
import '../datasources/transfer_remote_datasource.dart';

class FileTransferRepositoryImpl implements FileTransferRepository {
  final TransferRemoteDataSource remoteDataSource;

  FileTransferRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<RemoteFile>>> getFiles({
    required String token,
  }) async {
    try {
      final models = await remoteDataSource.getFiles(token);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RemoteFile>> uploadFile({
    required String token,
    required String filePath,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final model = await remoteDataSource.uploadFile(
        token: token,
        filePath: filePath,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadFile({
    required String token,
    required String fileName,
    required String savePath,
    required int startBytes,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final path = await remoteDataSource.downloadFile(
        token: token,
        fileName: fileName,
        savePath: savePath,
        startBytes: startBytes,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return Right(path);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteFile({
    required String token,
    required String fileName,
  }) async {
    try {
      final success = await remoteDataSource.deleteFile(
        token: token,
        fileName: fileName,
      );
      return Right(success);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
