import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/check_session.dart';
import 'app_session_event.dart';
import 'app_session_state.dart';

class AppSessionBloc extends Bloc<AppSessionEvent, AppSessionState> {
  final CheckSession checkSession;

  AppSessionBloc({required this.checkSession}) : super(const SessionInitial()) {
    on<AppSessionCheckRequested>(_onCheckRequested);
    on<AppSessionLoggedIn>(_onLoggedIn);
    on<AppSessionLoggedOut>(_onLoggedOut);
  }

  Future<void> _onCheckRequested(
    AppSessionCheckRequested event,
    Emitter<AppSessionState> emit,
  ) async {
    final result = await checkSession();
    result.fold((failure) => emit(const SessionUnauthenticated()), (data) {
      final (user, token) = data;
      if (user != null && token != null && token.isNotEmpty) {
        emit(SessionAuthenticated(user: user, token: token));
      } else {
        emit(const SessionUnauthenticated());
      }
    });
  }

  void _onLoggedIn(AppSessionLoggedIn event, Emitter<AppSessionState> emit) {
    emit(SessionAuthenticated(user: event.user, token: event.token));
  }

  void _onLoggedOut(AppSessionLoggedOut event, Emitter<AppSessionState> emit) {
    emit(const SessionUnauthenticated());
  }
}
