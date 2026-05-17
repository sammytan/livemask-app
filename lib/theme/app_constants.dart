import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design constants matching Atoms v2 spec.
///
/// - Max card radius: 8px
/// - Spacing scale: 4px base
/// - Consistent padding values
class AppConstants {
  AppConstants._();

  // ---- Radius ----
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;

  // ---- Spacing (4px grid) ----
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double space2xl = 32.0;
  static const double space3xl = 40.0;

  // ---- Padding ----
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingSm = EdgeInsets.all(12);

  // ---- Sizing ----
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // ---- Breakpoints ----
  static const double desktopBreakpoint = 960.0;
  static const double sidebarWidth = 240.0;
  static const double maxContentWidth = 672.0;

  // ---- Card decorations ----
  static BoxDecoration cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    );
  }

  static BoxDecoration cardDecorationSelected(BuildContext context) {
    return BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
    );
  }
}
