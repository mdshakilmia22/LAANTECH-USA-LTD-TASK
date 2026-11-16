import 'package:equatable/equatable.dart';

import '../../../domain/entities/remote_file.dart';

sealed class FileTransferEvent extends Equatable {
  const FileTransferEvent();

  @override
  List<Object?> get props => [];
}

final class LoadRemoteFilesRequested extends FileTransferEvent {
  final String token;

  const LoadRemoteFilesRequested({required this.token});

  @override
  List<Object?> get props => [token];
}

final class StartUploadRequested extends FileTransferEvent {
  final String token;
  final String filePath;

  const StartUploadRequested({required this.token, required this.filePath});

  @override
  List<Object?> get props => [token, filePath];
}

final class StartDownloadRequested extends FileTransferEvent {
  final String token;
  final RemoteFile remoteFile;

  const StartDownloadRequested({required this.token, required this.remoteFile});

  @override
  List<Object?> get props => [token, remoteFile];
}

final class PauseTransferRequested extends FileTransferEvent {
  final String taskId;

  const PauseTransferRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

final class ResumeTransferRequested extends FileTransferEvent {
  final String token;
  final String taskId;

  const ResumeTransferRequested({required this.token, required this.taskId});

  @override
  List<Object?> get props => [token, taskId];
}

final class CancelTransferRequested extends FileTransferEvent {
  final String taskId;

  const CancelTransferRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

final class PauseAllTransfersRequested extends FileTransferEvent {
  const PauseAllTransfersRequested();
}

final class ResumeAllTransfersRequested extends FileTransferEvent {
  final String token;

  const ResumeAllTransfersRequested({required this.token});

  @override
  List<Object?> get props => [token];
}

final class ClearCompletedTasksRequested extends FileTransferEvent {
  const ClearCompletedTasksRequested();
}

final class DeleteRemoteFileRequested extends FileTransferEvent {
  final String token;
  final String fileName;

  const DeleteRemoteFileRequested({
    required this.token,
    required this.fileName,
  });

  @override
  List<Object?> get props => [token, fileName];
}

final class UpdateTaskProgressInternal extends FileTransferEvent {
  final String taskId;
  final int transferredBytes;
  final int totalBytes;
  final double speedBytesPerSec;

  const UpdateTaskProgressInternal({
    required this.taskId,
    required this.transferredBytes,
    required this.totalBytes,
    required this.speedBytesPerSec,
  });

  @override
  List<Object?> get props => [
    taskId,
    transferredBytes,
    totalBytes,
    speedBytesPerSec,
  ];
}

final class TaskCompletedInternal extends FileTransferEvent {
  final String taskId;
  final String? savedPath;

  const TaskCompletedInternal({required this.taskId, this.savedPath});

  @override
  List<Object?> get props => [taskId, savedPath];
}

final class TaskFailedInternal extends FileTransferEvent {
  final String taskId;
  final String errorMessage;

  const TaskFailedInternal({required this.taskId, required this.errorMessage});

  @override
  List<Object?> get props => [taskId, errorMessage];
}
