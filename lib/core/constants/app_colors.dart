import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand accents - Modern POS Indigo & Cobalt
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryDark = Color(0xFF1D4ED8);
  static const onPrimary = Color(0xFFFFFFFF);

  // Modern Slate/Charcoal Dark Theme
  static const background = Color(0xFF0B0F19);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF131B2E);
  static const cardDark = Color(0xFF1A233A);
  static const cardElevatedDark = Color(0xFF222E4C);

  // Modern Slate Light Theme
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF1F5F9);
  static const lightBorder = Color(0xFFE2E8F0);

  // Typography
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const textDark = Color(0xFF0F172A);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightTextMuted = Color(0xFF94A3B8);

  // Borders & Dividers
  static const border = Color(0xFF24304D);
  static const borderLight = Color(0xFFE2E8F0);

  // Semantic States
  static const error = Color(0xFFF43F5E);
  static const errorLight = Color(0xFFFFE4E6);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const info = Color(0xFF38BDF8);

  // Transfer Status Tokens
  static const transferActive = Color(0xFF38BDF8);
  static const transferCompleted = Color(0xFF10B981);
  static const transferPaused = Color(0xFFF59E0B);
  static const transferFailed = Color(0xFFF43F5E);

  static const transparent = Colors.transparent;
}
