import 'package:equatable/equatable.dart';

import '../../../domain/entities/remote_file.dart';
import '../../../domain/entities/transfer_task.dart';

class FileTransferState extends Equatable {
  final List<TransferTask> tasks;
  final List<RemoteFile> remoteFiles;
  final bool isLoadingFiles;
  final String? errorMessage;
  final String? successMessage;

  const FileTransferState({
    this.tasks = const [],
    this.remoteFiles = const [],
    this.isLoadingFiles = false,
    this.errorMessage,
    this.successMessage,
  });

  FileTransferState copyWith({
    List<TransferTask>? tasks,
    List<RemoteFile>? remoteFiles,
    bool? isLoadingFiles,
    String? errorMessage,
    String? successMessage,
  }) {
    return FileTransferState(
      tasks: tasks ?? this.tasks,
      remoteFiles: remoteFiles ?? this.remoteFiles,
      isLoadingFiles: isLoadingFiles ?? this.isLoadingFiles,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  List<TransferTask> get activeTasks => tasks
      .where(
        (t) =>
            t.status == TransferStatus.transferring ||
            t.status == TransferStatus.pending,
      )
      .toList();

  List<TransferTask> get pausedTasks =>
      tasks.where((t) => t.status == TransferStatus.paused).toList();

  List<TransferTask> get completedTasks =>
      tasks.where((t) => t.status == TransferStatus.completed).toList();

  List<TransferTask> get failedTasks =>
      tasks.where((t) => t.status == TransferStatus.failed).toList();

  List<TransferTask> get uploads =>
      tasks.where((t) => t.type == TransferType.upload).toList();

  List<TransferTask> get downloads =>
      tasks.where((t) => t.type == TransferType.download).toList();

  @override
  List<Object?> get props => [
    tasks,
    remoteFiles,
    isLoadingFiles,
    errorMessage,
    successMessage,
  ];
}
