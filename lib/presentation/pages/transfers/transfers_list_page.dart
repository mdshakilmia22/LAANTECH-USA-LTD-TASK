import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
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

class TransfersListPage extends StatefulWidget {
  const TransfersListPage({super.key});

  @override
  State<TransfersListPage> createState() => _TransfersListPageState();
}

class _TransfersListPageState extends State<TransfersListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TransferTask> _filterTasks(List<TransferTask> tasks, int index) {
    switch (index) {
      case 1:
        return tasks
            .where(
              (t) =>
                  t.status == TransferStatus.transferring ||
                  t.status == TransferStatus.pending,
            )
            .toList();
      case 2:
        return tasks.where((t) => t.type == TransferType.upload).toList();
      case 3:
        return tasks.where((t) => t.type == TransferType.download).toList();
      case 4:
        return tasks
            .where((t) => t.status == TransferStatus.completed)
            .toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Operations'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textSecondary
              : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'All Tasks'),
            Tab(text: 'Active'),
            Tab(text: 'Uploads'),
            Tab(text: 'Downloads'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      drawer: const PosDrawer(),
      body: BlocBuilder<FileTransferBloc, FileTransferState>(
        builder: (context, state) {
          final filteredTasks = _filterTasks(state.tasks, _tabController.index);
          final activeCount = state.activeTasks.length;
          final pausedOrFailedCount =
              state.pausedTasks.length + state.failedTasks.length;
          final completedCount = state.completedTasks.length;

          return Stack(
            children: [
              Column(
                children: [
                  if (activeCount > 0 ||
                      pausedOrFailedCount > 0 ||
                      completedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      color: isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.5)
                          : AppColors.lightSurfaceAlt,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (activeCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.pause_rounded,
                                    size: 15,
                                    color: AppColors.warning,
                                  ),
                                  label: const Text('Pause All'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                  ),
                                  onPressed: () {
                                    context.read<FileTransferBloc>().add(
                                      const PauseAllTransfersRequested(),
                                    );
                                  },
                                ),
                              ),
                            if (pausedOrFailedCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  label: const Text('Resume All'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                  ),
                                  onPressed: () {
                                    final sessionState = context
                                        .read<AppSessionBloc>()
                                        .state;
                                    final token =
                                        sessionState is SessionAuthenticated
                                        ? sessionState.token
                                        : '';
                                    context.read<FileTransferBloc>().add(
                                      ResumeAllTransfersRequested(token: token),
                                    );
                                  },
                                ),
                              ),
                            if (completedCount > 0)
                              OutlinedButton.icon(
                                icon: Icon(
                                  Icons.cleaning_services_rounded,
                                  size: 15,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                label: const Text('Clear Completed'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                ),
                                onPressed: () {
                                  context.read<FileTransferBloc>().add(
                                    const ClearCompletedTasksRequested(),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.swap_vert_rounded,
                                    size: 36,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No transfers in this view',
                                  style: AppTextStyles.h2.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Background transfer tasks will appear here in real time.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: AppSpacing.screenPadding,
                            itemCount: filteredTasks.length + 1,
                            itemBuilder: (context, index) {
                              if (index == filteredTasks.length) {
                                return const SizedBox(height: 80);
                              }
                              return TransferTaskCard(
                                task: filteredTasks[index],
                              );
                            },
                          ),
                  ),
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
}
