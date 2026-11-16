import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/transfer_task.dart';
import '../../blocs/file_transfer/file_transfer_bloc.dart';
import '../../blocs/file_transfer/file_transfer_event.dart';
import '../../blocs/file_transfer/file_transfer_state.dart';
import '../../blocs/session/app_session_bloc.dart';
import '../../blocs/session/app_session_state.dart';
import '../../widgets/shared/pos_drawer.dart';
import '../../widgets/shared/transfer_progress_banner.dart';
import '../../widgets/shared/transfer_task_card.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  bool _isGeneratingSample = false;

  Future<void> _pickAndUpload(BuildContext context) async {
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

  Future<void> _generateAndUploadSample(int sizeInMb) async {
    setState(() => _isGeneratingSample = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/POS_Catalog_Export_${sizeInMb}MB_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      final sink = file.openWrite();
      sink.writeln(
        'product_id,sku,barcode,name,category,brand,cost_price,retail_price,tax_percent,stock_quantity,reorder_point,warehouse_bay,supplier_name,updated_at,pos_notes',
      );

      final rowChunk =
          'PROD-88219,SKU-CAT-09,088381559812,POS Gourmet Arabica Dark Roast Whole Bean 2.5lb,Beverages & Coffee,Artisan Roasters,12.50,22.95,5.00,1200,150,Aisle-Coffee-12,Pacific Bean Importers,2026-11-15,"Bulk product catalog entry for retail POS inventory sync and audit report."\n' *
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
        setState(() => _isGeneratingSample = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Catalog Upload Module')),
      drawer: const PosDrawer(),
      body: BlocBuilder<FileTransferBloc, FileTransferState>(
        builder: (context, state) {
          final uploads = state.uploads;
          final activeUploads = uploads
              .where(
                (t) =>
                    t.status == TransferStatus.transferring ||
                    t.status == TransferStatus.pending,
              )
              .toList();

          return Stack(
            children: [
              ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Import Store Inventory Catalog',
                            style: AppTextStyles.h2.copyWith(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select product catalog files (>50MB supported). Multipart stream upload to gateway with live progress telemetry.',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildPill(
                                'CSV / Excel',
                                Icons.table_chart_outlined,
                              ),
                              _buildPill(
                                'High-Res Media',
                                Icons.image_outlined,
                              ),
                              _buildPill(
                                'Product Videos',
                                Icons.video_file_outlined,
                              ),
                              _buildPill(
                                'Audit Reports',
                                Icons.description_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _pickAndUpload(context),
                            icon: const Icon(Icons.file_open_rounded, size: 20),
                            label: const Text('Select File from Device'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isGeneratingSample
                                ? null
                                : () => _generateAndUploadSample(55),
                            icon: _isGeneratingSample
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.post_add_rounded, size: 18),
                            label: Text(
                              _isGeneratingSample
                                  ? 'Generating Sample...'
                                  : 'Generate Sample Catalog (55 MB CSV)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (activeUploads.isNotEmpty) ...[
                    Row(
                      children: [
                        Text('Active Uploads', style: AppTextStyles.h2),
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
                            '${activeUploads.length}',
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
                    ...activeUploads.map(
                      (task) => TransferTaskCard(task: task),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text('Upload History', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.sm),
                  if (uploads.isEmpty)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 40,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No uploads recorded in this session.',
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
                    ...uploads.map((task) => TransferTaskCard(task: task)),
                  const SizedBox(height: 80),
                ],
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

  Widget _buildPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
