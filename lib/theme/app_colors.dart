import 'package:flutter/material.dart';

/// LiveMask design color tokens per Atoms v2 design system.
///
/// Primary palette: Deep teal / cyan-green
/// Success: Green
/// Warning: Amber
/// Danger: Red
/// Surface: Off-white / near-black in dark mode
/// Ink: Near-black / near-white text
/// Muted: Neutral gray
class AppColors {
  AppColors._();

  // ---- Primary ----
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFFE6F7F5);
  static const Color primaryDark = Color(0xFF0A7A70);

  // ---- Status ----
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);

  // ---- Surfaces ----
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // ---- Text ----
  static const Color ink = Color(0xFF0F172A);
  static const Color inkDark = Color(0xFFF1F5F9);
  static const Color muted = Color(0xFF94A3B8);
  static const Color mutedDark = Color(0xFF64748B);

  // ---- Sidebar ----
  static const Color sidebarBg = Color(0xFFFAFAFA);
  static const Color sidebarBgDark = Color(0xFF18181B);
  static const Color sidebarActiveBg = Color(0xFFE6F7F5);
  static const Color sidebarActiveBgDark = Color(0xFF1A2E2B);
  static const Color sidebarActiveFg = Color(0xFF0D7A6E);
  static const Color sidebarActiveFgDark = Color(0xFF5EEAD4);

  /// Returns the Material scheme for LiveMask (light).
  static ColorScheme lightScheme() {
    return ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      onPrimaryContainer: primaryDark,
      secondary: const Color(0xFF64748B),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF1F5F9),
      onSecondaryContainer: const Color(0xFF1E293B),
      tertiary: success,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      errorContainer: dangerBg,
      onErrorContainer: const Color(0xFF991B1B),
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: const Color(0xFFCBD5E1),
      shadow: Colors.black.withOpacity(0.08),
    );
  }

  /// Returns the Material scheme for LiveMask (dark).
  static ColorScheme darkScheme() {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF5EEAD4),
      onPrimary: const Color(0xFF0F2D2A),
      primaryContainer: const Color(0xFF134E4A),
      onPrimaryContainer: const Color(0xFFA7F3D0),
      secondary: const Color(0xFF94A3B8),
      onSecondary: const Color(0xFF1E293B),
      secondaryContainer: const Color(0xFF334155),
      onSecondaryContainer: const Color(0xFFE2E8F0),
      tertiary: const Color(0xFF4ADE80),
      onTertiary: const Color(0xFF052E16),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFECACA),
      surface: surfaceDark,
      onSurface: inkDark,
      surfaceContainerHighest: const Color(0xFF1E293B),
      onSurfaceVariant: mutedDark,
      outline: borderDark,
      outlineVariant: const Color(0xFF475569),
      shadow: Colors.black.withOpacity(0.3),
    );
  }
}
