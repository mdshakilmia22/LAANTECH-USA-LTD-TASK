import 'package:equatable/equatable.dart';

enum TransferType { upload, download }

enum TransferStatus { pending, transferring, paused, completed, failed }

class TransferTask extends Equatable {
  final String id;
  final String fileName;
  final String filePath;
  final TransferType type;
  final TransferStatus status;
  final int totalBytes;
  final int transferredBytes;
  final double progress;
  final double speedBytesPerSec;
  final String? errorMessage;
  final String? remoteUrl;
  final int notificationId;

  const TransferTask({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.status,
    required this.totalBytes,
    required this.transferredBytes,
    required this.progress,
    required this.speedBytesPerSec,
    this.errorMessage,
    this.remoteUrl,
    required this.notificationId,
  });

  TransferTask copyWith({
    String? id,
    String? fileName,
    String? filePath,
    TransferType? type,
    TransferStatus? status,
    int? totalBytes,
    int? transferredBytes,
    double? progress,
    double? speedBytesPerSec,
    String? errorMessage,
    String? remoteUrl,
    int? notificationId,
  }) {
    return TransferTask(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      status: status ?? this.status,
      totalBytes: totalBytes ?? this.totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      progress: progress ?? this.progress,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      errorMessage: errorMessage ?? this.errorMessage,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fileName,
    filePath,
    type,
    status,
    totalBytes,
    transferredBytes,
    progress,
    speedBytesPerSec,
    errorMessage,
    remoteUrl,
    notificationId,
  ];
}
