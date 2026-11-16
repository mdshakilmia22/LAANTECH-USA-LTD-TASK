import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase? registerUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    this.registerUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await loginUseCase(
      email: event.email,
      password: event.password,
    );
    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (user) async {
        final tokenResult = await authRepository.getSavedToken();
        final token = tokenResult.fold((_) => '', (t) => t ?? '');
        emit(AuthSuccess(user, token));
      },
    );
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = registerUseCase != null
        ? await registerUseCase!(
            username: event.username,
            password: event.password,
          )
        : await authRepository.register(
            username: event.username,
            password: event.password,
          );
    await result.fold(
      (failure) async => emit(AuthFailureState(failure.message)),
      (user) async {
        final tokenResult = await authRepository.getSavedToken();
        final token = tokenResult.fold((_) => '', (t) => t ?? '');
        emit(AuthSuccess(user, token));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await authRepository.logout();
    emit(const AuthInitial());
  }
}
