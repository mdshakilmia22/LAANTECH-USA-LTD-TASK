import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/session/app_session_bloc.dart';
import '../../blocs/session/app_session_event.dart';
import '../../widgets/common/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isRegisterMode) {
      context.read<AuthBloc>().add(
        RegisterSubmitted(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } else {
      context.read<AuthBloc>().add(
        LoginSubmitted(
          email: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _fillPresetCredentials() {
    _usernameController.text = 'shakil_pos';
    _passwordController.text = 'Password123';
    if (_isRegisterMode) {
      setState(() => _isRegisterMode = false);
    }
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthFailureState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (state is AuthSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isRegisterMode
                              ? 'Account created successfully. Welcome!'
                              : 'Terminal authenticated.',
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context.read<AppSessionBloc>().add(
                      AppSessionLoggedIn(user: state.user, token: state.token),
                    );
                  }
                },
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.point_of_sale_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'LAAN POS',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 26,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Terminal File Transfer & Catalog Sync',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Gateway: 108.136.142.112:90 • Online',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : AppColors.lightSurfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.border
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                onTap: () =>
                                    setState(() => _isRegisterMode = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isRegisterMode
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    'Terminal Sign In',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyBold.copyWith(
                                      color: !_isRegisterMode
                                          ? Colors.white
                                          : (isDark
                                                ? AppColors.textSecondary
                                                : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                onTap: () =>
                                    setState(() => _isRegisterMode = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isRegisterMode
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    'New Account',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyBold.copyWith(
                                      color: _isRegisterMode
                                          ? Colors.white
                                          : (isDark
                                                ? AppColors.textSecondary
                                                : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter operator username',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Username is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Password is required'
                            : (value.length < 4
                                  ? 'Password must be at least 4 characters'
                                  : null),
                      ),
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_reset_outlined,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 22),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return CustomButton(
                            text: _isRegisterMode
                                ? 'Create Operator Account'
                                : 'Authenticate Terminal',
                            isLoading: state is AuthLoading,
                            onPressed: _submit,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _fillPresetCredentials,
                        icon: const Icon(
                          Icons.vpn_key_outlined,
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        label: const Text('Use Preset Account (shakil_pos)'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'LAAN POS Terminal Services • Build v1.0.4',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.lightTextMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
