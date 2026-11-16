import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/remote_file.dart';
import '../repositories/file_transfer_repository.dart';

class GetFilesUseCase {
  final FileTransferRepository repository;

  GetFilesUseCase(this.repository);

  Future<Either<Failure, List<RemoteFile>>> call({required String token}) {
    return repository.getFiles(token: token);
  }
}
