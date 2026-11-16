import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';

sealed class AppSessionEvent extends Equatable {
  const AppSessionEvent();

  @override
  List<Object?> get props => [];
}

final class AppSessionCheckRequested extends AppSessionEvent {
  const AppSessionCheckRequested();
}

final class AppSessionLoggedIn extends AppSessionEvent {
  final User user;
  final String token;

  const AppSessionLoggedIn({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

final class AppSessionLoggedOut extends AppSessionEvent {
  const AppSessionLoggedOut();
}
