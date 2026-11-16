import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/blocs/session/app_session_bloc.dart';
import '../../presentation/blocs/session/app_session_state.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/dashboard/pos_dashboard_page.dart';
import '../../presentation/pages/download/download_page.dart';
import '../../presentation/pages/transfers/transfers_list_page.dart';
import '../../presentation/pages/upload/upload_page.dart';
import '../services/notification_service.dart';
import 'go_router_refresh_stream.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String upload = '/upload';
  static const String download = '/download';
  static const String transfers = '/transfers';
}

abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter? _routerInstance;

  static GoRouter router(AppSessionBloc sessionBloc) {
    return _routerInstance ??= GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation:
          NotificationService.instance.initialPayload ?? AppRoutes.home,
      refreshListenable: GoRouterRefreshStream(sessionBloc.stream),
      redirect: (BuildContext context, GoRouterState state) {
        final sessionState = sessionBloc.state;
        final isAuthenticated = sessionState is SessionAuthenticated;
        final isLoggingIn = state.matchedLocation == AppRoutes.login;

        if (!isAuthenticated && !isLoggingIn) {
          return AppRoutes.login;
        }

        if (isAuthenticated && isLoggingIn) {
          return AppRoutes.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const PosDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.upload,
          builder: (context, state) => const UploadPage(),
        ),
        GoRoute(
          path: AppRoutes.download,
          builder: (context, state) => const DownloadPage(),
        ),
        GoRoute(
          path: AppRoutes.transfers,
          builder: (context, state) => const TransfersListPage(),
        ),
      ],
    );
  }

  static void navigateTo(String path) {
    if (_routerInstance != null) {
      _routerInstance!.go(path);
    }
  }
}
