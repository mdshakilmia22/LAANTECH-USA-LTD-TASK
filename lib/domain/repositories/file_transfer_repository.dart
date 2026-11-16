import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/remote_file.dart';

abstract class FileTransferRepository {
  Future<Either<Failure, List<RemoteFile>>> getFiles({required String token});

  Future<Either<Failure, RemoteFile>> uploadFile({
    required String token,
    required String filePath,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, String>> downloadFile({
    required String token,
    required String fileName,
    required String savePath,
    required int startBytes,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, bool>> deleteFile({
    required String token,
    required String fileName,
  });
}
