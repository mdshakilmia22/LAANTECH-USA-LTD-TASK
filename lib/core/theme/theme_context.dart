import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBgColor =>
      isDark ? AppColors.background : AppColors.lightBackground;

  Color get textPrimaryColor =>
      isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

  Color get textSecondaryColor =>
      isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

  Color get primaryColor => AppColors.primary;
  Color get errorColor => AppColors.error;
  Color get surfaceColor =>
      isDark ? AppColors.surfaceDark : AppColors.lightSurface;
}
