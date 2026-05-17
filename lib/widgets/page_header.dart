import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Consistent page header with LiveMask branding and optional settings button.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    this.title,
    this.actions,
    this.showLogo = false,
  });

  final String? title;
  final List<Widget>? actions;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (showLogo) ...[
                Icon(
                  Icons.shield_outlined,
                  size: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'LiveMask',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
              ] else ...[
                if (title != null)
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
              ],
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
