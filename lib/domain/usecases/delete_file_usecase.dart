import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../repositories/file_transfer_repository.dart';

class DeleteFileUseCase {
  final FileTransferRepository repository;

  DeleteFileUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String token,
    required String fileName,
  }) {
    return repository.deleteFile(token: token, fileName: fileName);
  }
}
