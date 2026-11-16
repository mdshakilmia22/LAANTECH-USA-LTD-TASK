import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/remote_file.dart';
import '../../../domain/entities/transfer_task.dart';
import '../../blocs/file_transfer/file_transfer_bloc.dart';
import '../../blocs/file_transfer/file_transfer_event.dart';
import '../../blocs/file_transfer/file_transfer_state.dart';
import '../../blocs/session/app_session_bloc.dart';
import '../../blocs/session/app_session_state.dart';
import '../../widgets/shared/pos_drawer.dart';
import '../../widgets/shared/transfer_progress_banner.dart';
import '../../widgets/shared/transfer_task_card.dart';

class PosDashboardPage extends StatefulWidget {
  const PosDashboardPage({super.key});

  @override
  State<PosDashboardPage> createState() => _PosDashboardPageState();
}

class _PosDashboardPageState extends State<PosDashboardPage> {
  bool _isGeneratingFile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRemoteFiles();
    });
  }

  void _fetchRemoteFiles() {
    final sessionState = context.read<AppSessionBloc>().state;
    if (sessionState is SessionAuthenticated) {
      context.read<FileTransferBloc>().add(
        LoadRemoteFilesRequested(token: sessionState.token),
      );
    }
  }

  Future<void> _pickAndUploadFile() async {
    final sessionBloc = context.read<AppSessionBloc>();
    final fileTransferBloc = context.read<FileTransferBloc>();

    final result = await FilePicker.pickFiles(type: FileType.any);

    if (result.isNotEmpty && result.first.path != null) {
      final filePath = result.first.path!;
      final sessionState = sessionBloc.state;
      if (sessionState is SessionAuthenticated) {
        fileTransferBloc.add(
          StartUploadRequested(token: sessionState.token, filePath: filePath),
        );
      }
    }
  }

  Future<void> _generateAndUploadSampleFile(int sizeInMb) async {
    setState(() => _isGeneratingFile = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/POS_Catalog_Export_${sizeInMb}MB_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      final sink = file.openWrite();
      sink.writeln(
        'id,sku,barcode,name,category,brand,cost_price,retail_price,tax_rate,stock_qty,reorder_level,location,supplier,created_at,description',
      );

      final rowChunk =
          'ITEM-10023,SKU-9901,079357318921,Fresh Organic Avocado 4pk,Fresh Produce,NatureFresh,2.15,3.99,0.00,450,50,Aisle-04-A,GreenValley Farms,2026-11-15,"High quality Hass avocados ready for POS retail checkout barcode scan."\n' *
          380;
      final chunkBytes = utf8.encode(rowChunk).length;
      final totalTarget = sizeInMb * 1024 * 1024;
      int written = 0;
      while (written < totalTarget) {
        sink.write(rowChunk);
        written += chunkBytes;
      }
      await sink.flush();
      await sink.close();

      if (mounted) {
        final sessionState = context.read<AppSessionBloc>().state;
        if (sessionState is SessionAuthenticated) {
          context.read<FileTransferBloc>().add(
            StartUploadRequested(
              token: sessionState.token,
              filePath: file.path,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingFile = false);
      }
    }
  }

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

  IconData _getFileIcon(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv') ||
        lower.endsWith('.xlsx') ||
        lower.endsWith('.xls')) {
      return Icons.table_chart_outlined;
    } else if (lower.endsWith('.jpg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.jpeg')) {
      return Icons.image_outlined;
    } else if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi')) {
      return Icons.video_file_outlined;
    } else if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    } else if (lower.endsWith('.zip') || lower.endsWith('.tar')) {
      return Icons.archive_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionState = context.watch<AppSessionBloc>().state;
    final username = sessionState is SessionAuthenticated
        ? sessionState.user.name
        : 'POS User';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'POS Data Sync',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              'Terminal Transfer Dashboard',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Server Catalog',
            onPressed: _fetchRemoteFiles,
          ),
          BlocBuilder<FileTransferBloc, FileTransferState>(
            builder: (context, state) {
              final activeCount = state.activeTasks.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_vert_rounded),
                    tooltip: 'Transfer Manager',
                    onPressed: () => context.go(AppRoutes.transfers),
                  ),
                  if (activeCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: const PosDrawer(),
      body: BlocConsumer<FileTransferBloc, FileTransferState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final totalFiles = state.remoteFiles.length;
          final activeCount = state.activeTasks.length;
          final uploadCount = state.uploads
              .where((t) => t.status == TransferStatus.completed)
              .length;
          final downloadCount = state.downloads
              .where((t) => t.status == TransferStatus.completed)
              .length;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => _fetchRemoteFiles(),
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E293B),
                                  const Color(0xFF0F172A),
                                ]
                              : [AppColors.primary, const Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Terminal #01 • $username',
                                  style: AppTextStyles.h2.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Gateway: 108.136.142.112:90 • Online',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Server Catalog',
                            value: '$totalFiles',
                            icon: Icons.folder_special_outlined,
                            accentColor: AppColors.info,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Active Tasks',
                            value: '$activeCount',
                            icon: Icons.sync_rounded,
                            accentColor: AppColors.warning,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Synced Uploads',
                            value: '$uploadCount',
                            icon: Icons.cloud_done_outlined,
                            accentColor: AppColors.primaryLight,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Saved Downloads',
                            value: '$downloadCount',
                            icon: Icons.download_done_rounded,
                            accentColor: AppColors.success,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catalog Transfer Operations',
                              style: AppTextStyles.h2.copyWith(fontSize: 17),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Import large product catalogs (>50MB) or sync inventory items directly with store cloud services.',
                              style: AppTextStyles.body.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickAndUploadFile,
                                    icon: const Icon(
                                      Icons.upload_file_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Pick & Upload'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        context.go(AppRoutes.download),
                                    icon: const Icon(
                                      Icons.cloud_download_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Browse Server'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _isGeneratingFile
                                    ? null
                                    : () => _generateAndUploadSampleFile(55),
                                icon: _isGeneratingFile
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.post_add_rounded,
                                        color: AppColors.warning,
                                        size: 18,
                                      ),
                                label: Text(
                                  _isGeneratingFile
                                      ? 'Generating 55MB Sample Catalog...'
                                      : 'Generate & Stream Sample Catalog (55 MB CSV)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.activeTasks.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Active Transfers',
                                style: AppTextStyles.h2.copyWith(fontSize: 17),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${state.activeTasks.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.transfers),
                            child: const Text('Manager'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...state.activeTasks
                          .take(3)
                          .map((task) => TransferTaskCard(task: task)),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remote Catalog Files',
                          style: AppTextStyles.h2.copyWith(fontSize: 17),
                        ),
                        Row(
                          children: [
                            if (state.isLoadingFiles)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            TextButton(
                              onPressed: () => context.go(AppRoutes.download),
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (state.remoteFiles.isEmpty)
                      Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.cloud_off_rounded,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'No files found on server yet.',
                                  style: AppTextStyles.body.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...state.remoteFiles
                          .take(5)
                          .map(
                            (file) => _buildRemoteFileItem(
                              file: file,
                              isDark: isDark,
                              context: context,
                            ),
                          ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: TransferProgressBanner(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRemoteFileItem({
    required RemoteFile file,
    required bool isDark,
    required BuildContext context,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getFileIcon(file.originalName),
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          file.originalName,
          style: AppTextStyles.h3.copyWith(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatBytes(file.size)} • ${file.uploadedAt}',
          style: AppTextStyles.caption.copyWith(
            color: isDark
                ? AppColors.textSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, color: AppColors.primary),
          tooltip: 'Download File',
          onPressed: () {
            final sessionState = context.read<AppSessionBloc>().state;
            if (sessionState is SessionAuthenticated) {
              context.read<FileTransferBloc>().add(
                StartDownloadRequested(
                  token: sessionState.token,
                  remoteFile: file,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading ${file.originalName}...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? Colors.white : AppColors.textDark,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    title,
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
          ],
        ),
      ),
    );
  }
}
