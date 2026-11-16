import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/file_transfer/file_transfer_bloc.dart';
import '../../blocs/file_transfer/file_transfer_state.dart';
import '../../blocs/session/app_session_bloc.dart';
import '../../blocs/session/app_session_event.dart';
import '../../blocs/session/app_session_state.dart';

class PosDrawer extends StatelessWidget {
  const PosDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final sessionState = context.watch<AppSessionBloc>().state;
    final themeNotifier = ThemeScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final username = sessionState is SessionAuthenticated
        ? sessionState.user.name
        : 'POS User';

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F33) : AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'P',
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LAAN POS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
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
                            const SizedBox(width: 4),
                            const Text(
                              'Terminal #01 • Online',
                              style: TextStyle(
                                color: Colors.white60,
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
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, size: 22),
              title: const Text('POS Dashboard'),
              selected: currentRoute == AppRoutes.home,
              selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.home);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined, size: 22),
              title: const Text('Upload Module'),
              subtitle: const Text(
                'Import catalog & media',
                style: TextStyle(fontSize: 11),
              ),
              selected: currentRoute == AppRoutes.upload,
              selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.upload);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined, size: 22),
              title: const Text('Download Module'),
              subtitle: const Text(
                'Server catalog & sync',
                style: TextStyle(fontSize: 11),
              ),
              selected: currentRoute == AppRoutes.download,
              selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.download);
              },
            ),
            BlocBuilder<FileTransferBloc, FileTransferState>(
              builder: (context, state) {
                final activeCount = state.activeTasks.length;
                return ListTile(
                  leading: const Icon(
                    Icons.swap_vertical_circle_outlined,
                    size: 22,
                  ),
                  title: const Text('Transfer Operations'),
                  trailing: activeCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  selected: currentRoute == AppRoutes.transfers,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppRoutes.transfers);
                  },
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 22,
              ),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: isDark,
                activeThumbColor: AppColors.primary,
                onChanged: (_) => themeNotifier.toggle(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161F33)
                      : AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isDark ? AppColors.border : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.dns_outlined,
                      size: 15,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gateway: 108.136.142.112:90',
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22,
              ),
              title: Text(
                'Logout Session',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text(
                      'Are you sure you want to log out of this POS terminal session?',
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
                          Navigator.pop(context);
                          context.read<AuthBloc>().add(const LogoutRequested());
                          context.read<AppSessionBloc>().add(
                            const AppSessionLoggedOut(),
                          );
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
