import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
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

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchRemoteFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchRemoteFiles() {
    final sessionState = context.read<AppSessionBloc>().state;
    if (sessionState is SessionAuthenticated) {
      context.read<FileTransferBloc>().add(
        LoadRemoteFilesRequested(token: sessionState.token),
      );
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

  bool _matchesCategory(String fileName, String category) {
    if (category == 'All') return true;
    final lower = fileName.toLowerCase();
    switch (category) {
      case 'CSV':
        return lower.endsWith('.csv') ||
            lower.endsWith('.xlsx') ||
            lower.endsWith('.xls');
      case 'Images':
        return lower.endsWith('.jpg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp');
      case 'Videos':
        return lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.avi');
      case 'Docs':
        return lower.endsWith('.pdf') ||
            lower.endsWith('.txt') ||
            lower.endsWith('.json');
      default:
        return true;
    }
  }

  void _confirmDeleteFile(BuildContext context, RemoteFile file) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete File from Gateway?'),
        content: Text(
          'Are you sure you want to delete "${file.originalName}" from the remote store server?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              final sessionState = context.read<AppSessionBloc>().state;
              if (sessionState is SessionAuthenticated) {
                context.read<FileTransferBloc>().add(
                  DeleteRemoteFileRequested(
                    token: sessionState.token,
                    fileName: file.name,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog Download Module'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Server Files',
            onPressed: _fetchRemoteFiles,
          ),
        ],
      ),
      drawer: const PosDrawer(),
      body: BlocBuilder<FileTransferBloc, FileTransferState>(
        builder: (context, state) {
          final downloads = state.downloads;
          final activeDownloads = downloads
              .where(
                (t) =>
                    t.status == TransferStatus.transferring ||
                    t.status == TransferStatus.pending,
              )
              .toList();

          final filteredFiles = state.remoteFiles.where((file) {
            final matchesQuery =
                _searchQuery.isEmpty ||
                file.originalName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                file.name.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesCat = _matchesCategory(
              file.originalName,
              _selectedCategory,
            );
            return matchesQuery && matchesCat;
          }).toList();

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => _fetchRemoteFiles(),
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.cloud_download_rounded,
                                color: AppColors.success,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Download Catalog & Media',
                                    style: AppTextStyles.h2.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Resumable range downloads with automatic byte recovery. Saved to POS_Downloads directory.',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondary
                                          : AppColors.lightTextSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search server catalog by filename...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'CSV', 'Images', 'Videos', 'Docs']
                            .map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => _selectedCategory = cat);
                                  },
                                  selectedColor: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.textSecondary
                                              : AppColors.lightTextSecondary),
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.border
                                              : AppColors.lightBorder),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (activeDownloads.isNotEmpty) ...[
                      Row(
                        children: [
                          Text('Active Downloads', style: AppTextStyles.h2),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${activeDownloads.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...activeDownloads.map(
                        (task) => TransferTaskCard(task: task),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Available Server Files',
                              style: AppTextStyles.h2.copyWith(fontSize: 17),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '(${state.remoteFiles.length})',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (state.isLoadingFiles)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (filteredFiles.isEmpty)
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
                                  _searchQuery.isNotEmpty
                                      ? 'No files matching "$_searchQuery".'
                                      : 'No files available on remote server.',
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
                      ...filteredFiles.map(
                        (file) => Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Download File (Resumable)',
                                  onPressed: () {
                                    final sessionState = context
                                        .read<AppSessionBloc>()
                                        .state;
                                    if (sessionState is SessionAuthenticated) {
                                      context.read<FileTransferBloc>().add(
                                        StartDownloadRequested(
                                          token: sessionState.token,
                                          remoteFile: file,
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Starting download: ${file.originalName}',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete File from Server',
                                  onPressed: () =>
                                      _confirmDeleteFile(context, file),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Download History', style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.sm),
                    if (downloads.isEmpty)
                      Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.download_done_rounded,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'No download history recorded in this session.',
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
                      ...downloads.map((task) => TransferTaskCard(task: task)),
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
}
