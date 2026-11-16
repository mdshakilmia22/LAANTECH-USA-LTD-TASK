import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/remote_file.dart';
import '../repositories/file_transfer_repository.dart';

class UploadFileUseCase {
  final FileTransferRepository repository;

  UploadFileUseCase(this.repository);

  Future<Either<Failure, RemoteFile>> call({
    required String token,
    required String filePath,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  }) {
    return repository.uploadFile(
      token: token,
      filePath: filePath,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}
