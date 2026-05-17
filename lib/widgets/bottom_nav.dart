import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Four-tab mobile bottom navigation matching Atoms design.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  final String currentPath;
  final void Function(String path) onNavigate;

  static const tabs = [
    _NavTab(path: '/home', label: 'Home', icon: Icons.home_outlined),
    _NavTab(path: '/nodes', label: 'Nodes', icon: Icons.language_outlined),
    _NavTab(path: '/plan', label: 'Plan', icon: Icons.credit_card_outlined),
    _NavTab(path: '/profile', label: 'Profile', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: tabs.map((tab) {
              final isActive = currentPath == tab.path ||
                  (tab.path == '/home' && currentPath == '/home');
              return Expanded(
                child: InkWell(
                  onTap: () => onNavigate(tab.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 22,
                        color: isActive ? AppColors.primary : AppColors.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isActive ? AppColors.primary : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final String path;
  final String label;
  final IconData icon;

  const _NavTab({
    required this.path,
    required this.label,
    required this.icon,
  });
}
