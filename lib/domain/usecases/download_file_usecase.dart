import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../repositories/file_transfer_repository.dart';

class DownloadFileUseCase {
  final FileTransferRepository repository;

  DownloadFileUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String token,
    required String fileName,
    required String savePath,
    required int startBytes,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  }) {
    return repository.downloadFile(
      token: token,
      fileName: fileName,
      savePath: savePath,
      startBytes: startBytes,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}
