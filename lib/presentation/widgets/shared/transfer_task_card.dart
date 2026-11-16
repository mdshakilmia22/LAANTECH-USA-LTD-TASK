import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/transfer_task.dart';
import '../../blocs/file_transfer/file_transfer_bloc.dart';
import '../../blocs/file_transfer/file_transfer_event.dart';
import '../../blocs/session/app_session_bloc.dart';
import '../../blocs/session/app_session_state.dart';

class TransferTaskCard extends StatelessWidget {
  final TransferTask task;

  const TransferTaskCard({super.key, required this.task});

  String _formatBytes(int bytes) {
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

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '';
    return '${_formatBytes(bytesPerSec.toInt())}/s';
  }

  Color _statusColor() {
    switch (task.status) {
      case TransferStatus.transferring:
      case TransferStatus.pending:
        return AppColors.transferActive;
      case TransferStatus.completed:
        return AppColors.transferCompleted;
      case TransferStatus.paused:
        return AppColors.transferPaused;
      case TransferStatus.failed:
        return AppColors.transferFailed;
    }
  }

  IconData _taskIcon() {
    return task.type == TransferType.upload
        ? Icons.cloud_upload_outlined
        : Icons.cloud_download_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final pctInt = (task.progress * 100).toInt();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_taskIcon(), color: statusColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.fileName,
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task.type == TransferType.upload ? 'Upload' : 'Download'} • ${_formatBytes(task.totalBytes)}',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    task.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatBytes(task.transferredBytes)} / ${_formatBytes(task.totalBytes)}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                if (task.status == TransferStatus.transferring &&
                    task.speedBytesPerSec > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        Text(
                          _formatSpeed(task.speedBytesPerSec),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  '$pctInt%',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: statusColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                color: statusColor,
                minHeight: 6,
              ),
            ),
            if (task.status == TransferStatus.completed &&
                task.type == TransferType.download) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 15,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.filePath,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: task.filePath));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('File path copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (task.errorMessage != null &&
                task.status == TransferStatus.failed) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 15,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status == TransferStatus.transferring)
                  TextButton.icon(
                    icon: const Icon(Icons.pause_rounded, size: 16),
                    label: const Text('Pause'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      context.read<FileTransferBloc>().add(
                        PauseTransferRequested(task.id),
                      );
                    },
                  ),
                if (task.status == TransferStatus.paused ||
                    task.status == TransferStatus.failed)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(
                      task.status == TransferStatus.failed ? 'Retry' : 'Resume',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(70, 30),
                    ),
                    onPressed: () {
                      final sessionState = context.read<AppSessionBloc>().state;
                      final token = sessionState is SessionAuthenticated
                          ? sessionState.token
                          : '';
                      context.read<FileTransferBloc>().add(
                        ResumeTransferRequested(token: token, taskId: task.id),
                      );
                    },
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    task.status == TransferStatus.completed
                        ? Icons.check_circle_outline_rounded
                        : Icons.close_rounded,
                    size: 17,
                  ),
                  color: task.status == TransferStatus.completed
                      ? AppColors.success
                      : (isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary),
                  tooltip: task.status == TransferStatus.completed
                      ? 'Dismiss'
                      : 'Cancel',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    context.read<FileTransferBloc>().add(
                      CancelTransferRequested(task.id),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
