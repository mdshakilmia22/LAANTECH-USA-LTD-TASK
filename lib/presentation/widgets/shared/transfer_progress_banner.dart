import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/file_transfer/file_transfer_bloc.dart';
import '../../blocs/file_transfer/file_transfer_state.dart';

class TransferProgressBanner extends StatelessWidget {
  const TransferProgressBanner({super.key});

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '';
    if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<FileTransferBloc, FileTransferState>(
      builder: (context, state) {
        final activeTasks = state.activeTasks;
        if (activeTasks.isEmpty) {
          return const SizedBox.shrink();
        }

        final count = activeTasks.length;
        final firstTask = activeTasks.first;
        final avgProgress =
            activeTasks.fold(0.0, (sum, t) => sum + t.progress) / count;
        final pct = (avgProgress * 100).toInt();

        final totalSpeed = activeTasks.fold(
          0.0,
          (sum, t) => sum + t.speedBytesPerSec,
        );

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F33) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => context.go(AppRoutes.transfers),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 36,
                            width: 36,
                            child: CircularProgressIndicator(
                              value: avgProgress > 0 ? avgProgress : null,
                              strokeWidth: 3.5,
                              color: AppColors.primary,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$count Active Transfer${count > 1 ? 's' : ''}',
                                  style: AppTextStyles.h3.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (totalSpeed > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _formatSpeed(totalSpeed),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              firstTask.fileName,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
