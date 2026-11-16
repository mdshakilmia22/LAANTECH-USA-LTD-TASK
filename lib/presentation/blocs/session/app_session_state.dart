import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';

sealed class AppSessionState extends Equatable {
  const AppSessionState();

  @override
  List<Object?> get props => [];
}

final class SessionInitial extends AppSessionState {
  const SessionInitial();
}

final class SessionUnauthenticated extends AppSessionState {
  const SessionUnauthenticated();
}

final class SessionAuthenticated extends AppSessionState {
  final User user;
  final String token;

  const SessionAuthenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}
