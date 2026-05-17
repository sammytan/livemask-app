import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Reusable error/info/warning banner matching Atoms design.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.title,
    this.message,
    this.type = BannerType.warning,
    this.actions,
  });

  final String title;
  final String? message;
  final BannerType type;
  final List<Widget>? actions;

  factory ErrorBanner.info(String title, {String? message}) =>
      ErrorBanner(title: title, message: message, type: BannerType.info);

  factory ErrorBanner.warning(String title, {String? message}) =>
      ErrorBanner(title: title, message: message, type: BannerType.warning);

  factory ErrorBanner.danger(String title, {String? message}) =>
      ErrorBanner(title: title, message: message, type: BannerType.danger);

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg, IconData icon) = switch (type) {
      BannerType.info => (
        AppColors.primaryLight,
        AppColors.primary.withOpacity(0.2),
        const Color(0xFF0D7A6E),
        Icons.info_outline,
      ),
      BannerType.warning => (
        AppColors.warningBg,
        AppColors.warning.withOpacity(0.3),
        const Color(0xFF92400E),
        Icons.warning_amber_rounded,
      ),
      BannerType.danger => (
        AppColors.dangerBg,
        AppColors.danger.withOpacity(0.3),
        const Color(0xFF991B1B),
        Icons.error_outline,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                message!,
                style: TextStyle(fontSize: 12, color: fg),
              ),
            ),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: actions!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum BannerType { info, warning, danger }
