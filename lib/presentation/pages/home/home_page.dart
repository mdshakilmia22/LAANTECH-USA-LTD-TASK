import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_spacing.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/session/app_session_bloc.dart';
import '../../blocs/session/app_session_event.dart';
import '../../blocs/session/app_session_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
              context.read<AppSessionBloc>().add(const AppSessionLoggedOut());
            },
          ),
        ],
      ),
      body: BlocBuilder<AppSessionBloc, AppSessionState>(
        builder: (context, state) {
          if (state is SessionAuthenticated) {
            return Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      state.user.name.isNotEmpty
                          ? state.user.name[0].toUpperCase()
                          : 'U',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome, ${state.user.name}!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Welcome Guest'));
        },
      ),
    );
  }
}
