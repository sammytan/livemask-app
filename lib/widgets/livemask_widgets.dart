import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// LiveMask's reusable card widget with standard border radius and padding.
class LiveMaskCard extends StatelessWidget {
  const LiveMaskCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: selected
          ? AppConstants.cardDecorationSelected(context)
          : AppConstants.cardDecoration(context),
      child: Padding(
        padding: padding ?? AppConstants.cardPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: container,
      );
    }

    return container;
  }
}

/// Status badge showing a colored dot + text label.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.color,
    required this.label,
    this.textColor,
  });

  final Color color;
  final String label;
  final Color? textColor;

  factory StatusBadge.green(String label) =>
      StatusBadge(color: AppColors.success, label: label);

  factory StatusBadge.amber(String label) =>
      StatusBadge(color: AppColors.warning, label: label);

  factory StatusBadge.red(String label) =>
      StatusBadge(color: AppColors.danger, label: label);

  factory StatusBadge.grey(String label) =>
      StatusBadge(color: AppColors.muted, label: label);

  factory StatusBadge.teal(String label) =>
      StatusBadge(color: AppColors.primary, label: label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor ?? color,
          ),
        ),
      ],
    );
  }
}

/// A small metric tile for compact data display.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LiveMaskCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive breakpoint helper.
class Responsive extends StatelessWidget {
  const Responsive({
    super.key,
    required this.mobile,
    this.desktop,
    this.tablet,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < AppConstants.desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (desktop != null && width >= AppConstants.desktopBreakpoint) {
      return desktop!;
    }
    if (tablet != null && width >= 768) {
      return tablet!;
    }
    return mobile;
  }
}
