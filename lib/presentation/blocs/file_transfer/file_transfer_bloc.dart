import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../domain/entities/transfer_task.dart';
import '../../../domain/usecases/delete_file_usecase.dart';
import '../../../domain/usecases/download_file_usecase.dart';
import '../../../domain/usecases/get_files_usecase.dart';
import '../../../domain/usecases/upload_file_usecase.dart';
import 'file_transfer_event.dart';
import 'file_transfer_state.dart';

class FileTransferBloc extends Bloc<FileTransferEvent, FileTransferState> {
  final GetFilesUseCase getFilesUseCase;
  final UploadFileUseCase uploadFileUseCase;
  final DownloadFileUseCase downloadFileUseCase;
  final DeleteFileUseCase deleteFileUseCase;
  final NotificationService notificationService;

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, int> _lastTimestamps = {};
  final Map<String, int> _lastBytes = {};
  int _nextNotificationId = 100;

  FileTransferBloc({
    required this.getFilesUseCase,
    required this.uploadFileUseCase,
    required this.downloadFileUseCase,
    required this.deleteFileUseCase,
    required this.notificationService,
  }) : super(const FileTransferState()) {
    on<LoadRemoteFilesRequested>(_onLoadRemoteFilesRequested);
    on<StartUploadRequested>(_onStartUploadRequested);
    on<StartDownloadRequested>(_onStartDownloadRequested);
    on<PauseTransferRequested>(_onPauseTransferRequested);
    on<ResumeTransferRequested>(_onResumeTransferRequested);
    on<CancelTransferRequested>(_onCancelTransferRequested);
    on<PauseAllTransfersRequested>(_onPauseAllTransfersRequested);
    on<ResumeAllTransfersRequested>(_onResumeAllTransfersRequested);
    on<ClearCompletedTasksRequested>(_onClearCompletedTasksRequested);
    on<DeleteRemoteFileRequested>(_onDeleteRemoteFileRequested);
    on<UpdateTaskProgressInternal>(_onUpdateTaskProgressInternal);
    on<TaskCompletedInternal>(_onTaskCompletedInternal);
    on<TaskFailedInternal>(_onTaskFailedInternal);
  }

  Future<void> _onLoadRemoteFilesRequested(
    LoadRemoteFilesRequested event,
    Emitter<FileTransferState> emit,
  ) async {
    emit(state.copyWith(isLoadingFiles: true));
    final result = await getFilesUseCase(token: event.token);
    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingFiles: false, errorMessage: failure.message),
      ),
      (files) =>
          emit(state.copyWith(isLoadingFiles: false, remoteFiles: files)),
    );
  }

  Future<void> _onStartUploadRequested(
    StartUploadRequested event,
    Emitter<FileTransferState> emit,
  ) async {
    final file = File(event.filePath);
    if (!await file.exists()) {
      emit(state.copyWith(errorMessage: 'File not found at ${event.filePath}'));
      return;
    }

    final fileName = file.path.split(RegExp(r'[/\\]')).last;
    final fileSize = await file.length();
    final taskId = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final notifId = _nextNotificationId++;

    final task = TransferTask(
      id: taskId,
      fileName: fileName,
      filePath: event.filePath,
      type: TransferType.upload,
      status: TransferStatus.transferring,
      totalBytes: fileSize,
      transferredBytes: 0,
      progress: 0.0,
      speedBytesPerSec: 0.0,
      notificationId: notifId,
    );

    final updatedTasks = List<TransferTask>.from(state.tasks)..insert(0, task);
    emit(state.copyWith(tasks: updatedTasks));

    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    _executeUpload(
      token: event.token,
      taskId: taskId,
      filePath: event.filePath,
      cancelToken: cancelToken,
      notificationId: notifId,
      fileName: fileName,
    );
  }

  Future<void> _executeUpload({
    required String token,
    required String taskId,
    required String filePath,
    required CancelToken cancelToken,
    required int notificationId,
    required String fileName,
  }) async {
    _lastTimestamps[taskId] = DateTime.now().millisecondsSinceEpoch;
    _lastBytes[taskId] = 0;

    final result = await uploadFileUseCase(
      token: token,
      filePath: filePath,
      cancelToken: cancelToken,
      onProgress: (count, total) {
        _handleProgress(
          taskId: taskId,
          count: count,
          total: total,
          notificationId: notificationId,
          title: 'Uploading $fileName',
        );
      },
    );

    result.fold(
      (failure) {
        if (cancelToken.isCancelled) {
          // Handled by pause/cancel events
        } else {
          add(
            TaskFailedInternal(taskId: taskId, errorMessage: failure.message),
          );
        }
      },
      (remoteFile) {
        add(TaskCompletedInternal(taskId: taskId));
        add(LoadRemoteFilesRequested(token: token));
      },
    );
  }

  Future<void> _onStartDownloadRequested(
    StartDownloadRequested event,
    Emitter<FileTransferState> emit,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/POS_Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    final savePath = '${downloadDir.path}/${event.remoteFile.originalName}';
    final taskId = 'download_${DateTime.now().millisecondsSinceEpoch}';
    final notifId = _nextNotificationId++;

    final existingFile = File(savePath);
    final startBytes = await existingFile.exists()
        ? await existingFile.length()
        : 0;

    final task = TransferTask(
      id: taskId,
      fileName: event.remoteFile.originalName,
      filePath: savePath,
      type: TransferType.download,
      status: TransferStatus.transferring,
      totalBytes: event.remoteFile.size > 0 ? event.remoteFile.size : 1,
      transferredBytes: startBytes,
      progress: event.remoteFile.size > 0
          ? (startBytes / event.remoteFile.size).clamp(0.0, 1.0)
          : 0.0,
      speedBytesPerSec: 0.0,
      remoteUrl: event.remoteFile.name,
      notificationId: notifId,
    );

    final updatedTasks = List<TransferTask>.from(state.tasks)..insert(0, task);
    emit(state.copyWith(tasks: updatedTasks));

    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    _executeDownload(
      token: event.token,
      taskId: taskId,
      fileName: event.remoteFile.name,
      savePath: savePath,
      startBytes: startBytes,
      cancelToken: cancelToken,
      notificationId: notifId,
      displayFileName: event.remoteFile.originalName,
    );
  }

  Future<void> _executeDownload({
    required String token,
    required String taskId,
    required String fileName,
    required String savePath,
    required int startBytes,
    required CancelToken cancelToken,
    required int notificationId,
    required String displayFileName,
  }) async {
    _lastTimestamps[taskId] = DateTime.now().millisecondsSinceEpoch;
    _lastBytes[taskId] = startBytes;

    final result = await downloadFileUseCase(
      token: token,
      fileName: fileName,
      savePath: savePath,
      startBytes: startBytes,
      cancelToken: cancelToken,
      onProgress: (count, total) {
        _handleProgress(
          taskId: taskId,
          count: count,
          total: total,
          notificationId: notificationId,
          title: 'Downloading $displayFileName',
        );
      },
    );

    result.fold(
      (failure) {
        if (cancelToken.isCancelled) {
          // Handled by pause/cancel events
        } else {
          add(
            TaskFailedInternal(taskId: taskId, errorMessage: failure.message),
          );
        }
      },
      (path) {
        add(TaskCompletedInternal(taskId: taskId, savedPath: path));
      },
    );
  }

  void _handleProgress({
    required String taskId,
    required int count,
    required int total,
    required int notificationId,
    required String title,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastTimestamps[taskId] ?? now;
    final lastByte = _lastBytes[taskId] ?? count;
    final timeDiff = (now - lastTime) / 1000.0;

    double speed = 0.0;
    if (timeDiff >= 0.4) {
      speed = (count - lastByte) / timeDiff;
      _lastTimestamps[taskId] = now;
      _lastBytes[taskId] = count;
    }

    final progressPct = total > 0 ? ((count / total) * 100).toInt() : 0;

    notificationService.showProgressNotification(
      id: notificationId,
      title: title,
      body: '$progressPct% • ${_formatBytes(count)} / ${_formatBytes(total)}',
      progress: progressPct,
      maxProgress: 100,
      payload: '/transfers',
    );

    add(
      UpdateTaskProgressInternal(
        taskId: taskId,
        transferredBytes: count,
        totalBytes: total,
        speedBytesPerSec: speed > 0 ? speed : 0.0,
      ),
    );
  }

  void _onUpdateTaskProgressInternal(
    UpdateTaskProgressInternal event,
    Emitter<FileTransferState> emit,
  ) {
    final index = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (index == -1) return;

    final currentTask = state.tasks[index];
    final progress = event.totalBytes > 0
        ? (event.transferredBytes / event.totalBytes).clamp(0.0, 1.0)
        : 0.0;

    final updatedTask = currentTask.copyWith(
      transferredBytes: event.transferredBytes,
      totalBytes: event.totalBytes,
      progress: progress,
      speedBytesPerSec: event.speedBytesPerSec > 0
          ? event.speedBytesPerSec
          : currentTask.speedBytesPerSec,
      status: TransferStatus.transferring,
    );

    final updatedTasks = List<TransferTask>.from(state.tasks);
    updatedTasks[index] = updatedTask;
    emit(state.copyWith(tasks: updatedTasks));
  }

  void _onTaskCompletedInternal(
    TaskCompletedInternal event,
    Emitter<FileTransferState> emit,
  ) {
    final index = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (index == -1) return;

    final currentTask = state.tasks[index];
    final updatedTask = currentTask.copyWith(
      status: TransferStatus.completed,
      progress: 1.0,
      transferredBytes: currentTask.totalBytes,
      speedBytesPerSec: 0.0,
      filePath: event.savedPath ?? currentTask.filePath,
    );

    final updatedTasks = List<TransferTask>.from(state.tasks);
    updatedTasks[index] = updatedTask;

    notificationService.showCompletedNotification(
      id: currentTask.notificationId,
      title:
          '${currentTask.type == TransferType.upload ? 'Upload' : 'Download'} Completed',
      body: '${currentTask.fileName} transferred successfully.',
      payload: currentTask.type == TransferType.upload
          ? '/upload'
          : '/download',
    );

    _cancelTokens.remove(event.taskId);
    _lastTimestamps.remove(event.taskId);
    _lastBytes.remove(event.taskId);

    emit(
      state.copyWith(
        tasks: updatedTasks,
        successMessage: '${currentTask.fileName} completed successfully!',
      ),
    );
  }

  void _onTaskFailedInternal(
    TaskFailedInternal event,
    Emitter<FileTransferState> emit,
  ) {
    final index = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (index == -1) return;

    final currentTask = state.tasks[index];
    final updatedTask = currentTask.copyWith(
      status: TransferStatus.failed,
      errorMessage: event.errorMessage,
      speedBytesPerSec: 0.0,
    );

    final updatedTasks = List<TransferTask>.from(state.tasks);
    updatedTasks[index] = updatedTask;

    notificationService.showFailedNotification(
      id: currentTask.notificationId,
      title:
          '${currentTask.type == TransferType.upload ? 'Upload' : 'Download'} Failed',
      body: '${currentTask.fileName}: ${event.errorMessage}',
      payload: '/transfers',
    );

    _cancelTokens.remove(event.taskId);
    _lastTimestamps.remove(event.taskId);
    _lastBytes.remove(event.taskId);

    emit(state.copyWith(tasks: updatedTasks));
  }

  void _onPauseTransferRequested(
    PauseTransferRequested event,
    Emitter<FileTransferState> emit,
  ) {
    final cancelToken = _cancelTokens[event.taskId];
    cancelToken?.cancel('Paused by user');

    final index = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (index != -1) {
      final currentTask = state.tasks[index];
      final updatedTask = currentTask.copyWith(
        status: TransferStatus.paused,
        speedBytesPerSec: 0.0,
      );
      final updatedTasks = List<TransferTask>.from(state.tasks);
      updatedTasks[index] = updatedTask;

      notificationService.cancelNotification(currentTask.notificationId);
      emit(state.copyWith(tasks: updatedTasks));
    }
  }

  Future<void> _onResumeTransferRequested(
    ResumeTransferRequested event,
    Emitter<FileTransferState> emit,
  ) async {
    final index = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (index == -1) return;

    final currentTask = state.tasks[index];
    final updatedTask = currentTask.copyWith(
      status: TransferStatus.transferring,
      errorMessage: null,
    );

    final updatedTasks = List<TransferTask>.from(state.tasks);
    updatedTasks[index] = updatedTask;
    emit(state.copyWith(tasks: updatedTasks));

    final cancelToken = CancelToken();
    _cancelTokens[event.taskId] = cancelToken;

    if (currentTask.type == TransferType.upload) {
      _executeUpload(
        token: event.token,
        taskId: currentTask.id,
        filePath: currentTask.filePath,
        cancelToken: cancelToken,
        notificationId: currentTask.notificationId,
        fileName: currentTask.fileName,
      );
    } else {
      final existingFile = File(currentTask.filePath);
      final startBytes = await existingFile.exists()
          ? await existingFile.length()
          : 0;

      _executeDownload(
        token: event.token,
        taskId: currentTask.id,
        fileName: currentTask.remoteUrl ?? currentTask.fileName,
        savePath: currentTask.filePath,
        startBytes: startBytes,
        cancelToken: cancelToken,
        notificationId: currentTask.notificationId,
        displayFileName: currentTask.fileName,
      );
    }
  }

  void _onCancelTransferRequested(
    CancelTransferRequested event,
    Emitter<FileTransferState> emit,
  ) {
    final cancelToken = _cancelTokens[event.taskId];
    cancelToken?.cancel('Cancelled by user');

    final index = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (index != -1) {
      final currentTask = state.tasks[index];
      notificationService.cancelNotification(currentTask.notificationId);

      final updatedTasks = List<TransferTask>.from(state.tasks)
        ..removeAt(index);
      _cancelTokens.remove(event.taskId);
      _lastTimestamps.remove(event.taskId);
      _lastBytes.remove(event.taskId);
      emit(state.copyWith(tasks: updatedTasks));
    }
  }

  void _onPauseAllTransfersRequested(
    PauseAllTransfersRequested event,
    Emitter<FileTransferState> emit,
  ) {
    for (final token in _cancelTokens.values) {
      token.cancel('Paused by user');
    }
    _cancelTokens.clear();

    final updatedTasks = state.tasks.map((task) {
      if (task.status == TransferStatus.transferring ||
          task.status == TransferStatus.pending) {
        notificationService.cancelNotification(task.notificationId);
        return task.copyWith(
          status: TransferStatus.paused,
          speedBytesPerSec: 0.0,
        );
      }
      return task;
    }).toList();

    emit(state.copyWith(tasks: updatedTasks));
  }

  void _onResumeAllTransfersRequested(
    ResumeAllTransfersRequested event,
    Emitter<FileTransferState> emit,
  ) {
    for (final task in state.tasks) {
      if (task.status == TransferStatus.paused ||
          task.status == TransferStatus.failed) {
        add(ResumeTransferRequested(token: event.token, taskId: task.id));
      }
    }
  }

  void _onClearCompletedTasksRequested(
    ClearCompletedTasksRequested event,
    Emitter<FileTransferState> emit,
  ) {
    final updatedTasks = state.tasks
        .where((t) => t.status != TransferStatus.completed)
        .toList();
    emit(state.copyWith(tasks: updatedTasks));
  }

  Future<void> _onDeleteRemoteFileRequested(
    DeleteRemoteFileRequested event,
    Emitter<FileTransferState> emit,
  ) async {
    final result = await deleteFileUseCase(
      token: event.token,
      fileName: event.fileName,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (success) {
        emit(state.copyWith(successMessage: 'File deleted successfully'));
        add(LoadRemoteFilesRequested(token: event.token));
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
