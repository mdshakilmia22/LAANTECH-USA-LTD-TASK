import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:laan_tech_usa_technical_task/core/errors/failures.dart';
import 'package:laan_tech_usa_technical_task/core/services/notification_service.dart';
import 'package:laan_tech_usa_technical_task/domain/entities/remote_file.dart';
import 'package:laan_tech_usa_technical_task/domain/entities/transfer_task.dart';
import 'package:laan_tech_usa_technical_task/domain/repositories/file_transfer_repository.dart';
import 'package:laan_tech_usa_technical_task/domain/usecases/delete_file_usecase.dart';
import 'package:laan_tech_usa_technical_task/domain/usecases/download_file_usecase.dart';
import 'package:laan_tech_usa_technical_task/domain/usecases/get_files_usecase.dart';
import 'package:laan_tech_usa_technical_task/domain/usecases/upload_file_usecase.dart';
import 'package:laan_tech_usa_technical_task/presentation/blocs/file_transfer/file_transfer_bloc.dart';
import 'package:laan_tech_usa_technical_task/presentation/blocs/file_transfer/file_transfer_event.dart';
import 'package:laan_tech_usa_technical_task/presentation/blocs/file_transfer/file_transfer_state.dart';

class FakeFileTransferRepository implements FileTransferRepository {
  List<RemoteFile> files = [];

  @override
  Future<Either<Failure, List<RemoteFile>>> getFiles({
    required String token,
  }) async {
    return Right(files);
  }

  @override
  Future<Either<Failure, RemoteFile>> uploadFile({
    required String token,
    required String filePath,
    required void Function(int count, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    return const Right(
      RemoteFile(
        id: 1,
        name: 'uploaded.csv',
        originalName: 'catalog.csv',
        size: 1024,
        type: 'text/csv',
        uploadedAt: '2026-11-15',
        url: 'http://108.136.142.112:90/get?file=uploaded.csv',
      ),
    );
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
    return Right(savePath);
  }

  @override
  Future<Either<Failure, bool>> deleteFile({
    required String token,
    required String fileName,
  }) async {
    return const Right(true);
  }
}

void main() {
  late FakeFileTransferRepository repository;
  late FileTransferBloc bloc;

  setUp(() {
    repository = FakeFileTransferRepository();
    final getFilesUseCase = GetFilesUseCase(repository);
    final uploadFileUseCase = UploadFileUseCase(repository);
    final downloadFileUseCase = DownloadFileUseCase(repository);
    final deleteFileUseCase = DeleteFileUseCase(repository);

    bloc = FileTransferBloc(
      getFilesUseCase: getFilesUseCase,
      uploadFileUseCase: uploadFileUseCase,
      downloadFileUseCase: downloadFileUseCase,
      deleteFileUseCase: deleteFileUseCase,
      notificationService: NotificationService.instance,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state has empty task list and is not loading', () {
    expect(bloc.state, const FileTransferState());
    expect(bloc.state.tasks, isEmpty);
    expect(bloc.state.remoteFiles, isEmpty);
    expect(bloc.state.activeTasks, isEmpty);
  });

  test(
    'UpdateTaskProgressInternal updates task progress and bytes correctly',
    () async {
      const task = TransferTask(
        id: 'task_1',
        fileName: 'catalog.csv',
        filePath: '/tmp/catalog.csv',
        type: TransferType.upload,
        status: TransferStatus.transferring,
        totalBytes: 1000,
        transferredBytes: 0,
        progress: 0.0,
        speedBytesPerSec: 0.0,
        notificationId: 101,
      );

      bloc.emit(FileTransferState(tasks: [task]));

      bloc.add(
        const UpdateTaskProgressInternal(
          taskId: 'task_1',
          transferredBytes: 500,
          totalBytes: 1000,
          speedBytesPerSec: 250.0,
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<FileTransferState>((state) {
            final updated = state.tasks.firstWhere((t) => t.id == 'task_1');
            return updated.transferredBytes == 500 &&
                updated.progress == 0.5 &&
                updated.speedBytesPerSec == 250.0;
          }),
        ),
      );
    },
  );

  test('PauseTransferRequested changes task status to paused', () async {
    const task = TransferTask(
      id: 'task_1',
      fileName: 'catalog.csv',
      filePath: '/tmp/catalog.csv',
      type: TransferType.download,
      status: TransferStatus.transferring,
      totalBytes: 1000,
      transferredBytes: 300,
      progress: 0.3,
      speedBytesPerSec: 500.0,
      notificationId: 102,
    );

    bloc.emit(FileTransferState(tasks: [task]));
    bloc.add(const PauseTransferRequested('task_1'));

    await expectLater(
      bloc.stream,
      emits(
        predicate<FileTransferState>((state) {
          final updated = state.tasks.firstWhere((t) => t.id == 'task_1');
          return updated.status == TransferStatus.paused &&
              updated.speedBytesPerSec == 0.0;
        }),
      ),
    );
  });

  test('PauseAllTransfersRequested pauses all active tasks', () async {
    const task1 = TransferTask(
      id: 'task_1',
      fileName: 'catalog1.csv',
      filePath: '/tmp/c1.csv',
      type: TransferType.upload,
      status: TransferStatus.transferring,
      totalBytes: 1000,
      transferredBytes: 200,
      progress: 0.2,
      speedBytesPerSec: 100.0,
      notificationId: 103,
    );
    const task2 = TransferTask(
      id: 'task_2',
      fileName: 'catalog2.csv',
      filePath: '/tmp/c2.csv',
      type: TransferType.download,
      status: TransferStatus.transferring,
      totalBytes: 2000,
      transferredBytes: 500,
      progress: 0.25,
      speedBytesPerSec: 200.0,
      notificationId: 104,
    );

    bloc.emit(FileTransferState(tasks: [task1, task2]));
    bloc.add(const PauseAllTransfersRequested());

    await expectLater(
      bloc.stream,
      emits(
        predicate<FileTransferState>((state) {
          return state.tasks.every((t) => t.status == TransferStatus.paused);
        }),
      ),
    );
  });

  test('ClearCompletedTasksRequested removes completed tasks and retains active/paused', () async {
    const taskCompleted = TransferTask(
      id: 'task_1',
      fileName: 'done.csv',
      filePath: '/tmp/done.csv',
      type: TransferType.upload,
      status: TransferStatus.completed,
      totalBytes: 1000,
      transferredBytes: 1000,
      progress: 1.0,
      speedBytesPerSec: 0.0,
      notificationId: 105,
    );
    const taskActive = TransferTask(
      id: 'task_2',
      fileName: 'active.csv',
      filePath: '/tmp/active.csv',
      type: TransferType.download,
      status: TransferStatus.transferring,
      totalBytes: 2000,
      transferredBytes: 500,
      progress: 0.25,
      speedBytesPerSec: 200.0,
      notificationId: 106,
    );

    bloc.emit(FileTransferState(tasks: [taskCompleted, taskActive]));
    bloc.add(const ClearCompletedTasksRequested());

    await expectLater(
      bloc.stream,
      emits(
        predicate<FileTransferState>((state) {
          return state.tasks.length == 1 && state.tasks.first.id == 'task_2';
        }),
      ),
    );
  });
}
