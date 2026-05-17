import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Desktop left sidebar navigation matching Atoms design.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  final String currentPath;
  final void Function(String path) onNavigate;

  static const navItems = [
    _SidebarItem(path: '/home', label: 'Connect', icon: Icons.power_settings_new_outlined),
    _SidebarItem(path: '/nodes', label: 'Nodes', icon: Icons.language_outlined),
    _SidebarItem(path: '/plan', label: 'Plan', icon: Icons.credit_card_outlined),
    _SidebarItem(path: '/diagnostics', label: 'Diagnostics', icon: Icons.feedback_outlined),
    _SidebarItem(path: '/profile', label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? AppColors.sidebarBgDark : AppColors.sidebarBg,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          // Brand
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Text(
                  'LiveMask',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.muted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Disconnected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: navItems.map((item) {
                  final isActive = currentPath == item.path ||
                      (item.path == '/home' && currentPath == '/home');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onNavigate(item.path),
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark
                                    ? AppColors.sidebarActiveBgDark
                                    : AppColors.sidebarActiveBg)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusMd),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isActive
                                    ? (isDark
                                        ? AppColors.sidebarActiveFgDark
                                        : AppColors.sidebarActiveFg)
                                    : AppColors.muted,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isActive
                                      ? (isDark
                                          ? AppColors.sidebarActiveFgDark
                                          : AppColors.sidebarActiveFg)
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LiveMask v0.1.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final String path;
  final String label;
  final IconData icon;

  const _SidebarItem({
    required this.path,
    required this.label,
    required this.icon,
  });
}
