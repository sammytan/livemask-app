import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Profile / Settings screen matching Atoms design v2.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account section
                _SectionTitle('Account'),
                _SettingsCard(items: [
                  _SettingItem(
                    icon: Icons.person_outline,
                    label: 'Account',
                    value: authState.user?.email ?? 'Not signed in',
                  ),
                ]),

                const SizedBox(height: 24),

                // Security section
                _SectionTitle('Security'),
                _SettingsCard(items: [
                  _SettingItem(
                    icon: Icons.shield_outlined,
                    label: 'Certificate Pinning',
                    badge: 'Active',
                    badgeColor: AppColors.success,
                  ),
                  _SettingItem(
                    icon: Icons.phonelink_lock_outlined,
                    label: 'Device Trust',
                    badge: 'Verified',
                    badgeColor: AppColors.success,
                  ),
                  _SettingItem(
                    icon: Icons.lock_outlined,
                    label: 'Local Data Protection',
                    badge: 'Enabled',
                    badgeColor: AppColors.primary,
                  ),
                ]),

                const SizedBox(height: 24),

                // App Settings section
                _SectionTitle('App Settings'),
                _SettingsCard(items: [
                  _SettingItem(
                    icon: Icons.palette_outlined,
                    label: 'Dark Mode',
                    value: isDark ? 'On' : 'Off',
                  ),
                  _SettingItem(
                    icon: Icons.wifi_outlined,
                    label: 'Auto Connect',
                    value: 'Off',
                  ),
                ]),

                const SizedBox(height: 24),

                // Support section
                _SectionTitle('Support'),
                _SettingsCard(items: [
                  _SettingItem(
                    icon: Icons.feedback_outlined,
                    label: 'Send Diagnostic Report',
                  ),
                  _SettingItem(
                    icon: Icons.description_outlined,
                    label: 'Privacy Policy',
                  ),
                  _SettingItem(
                    icon: Icons.article_outlined,
                    label: 'Terms of Service',
                  ),
                ]),

                const SizedBox(height: 24),

                // Sign Out (if logged in)
                if (authState.isAuthenticated)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        onLogout();
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // App version
                Center(
                  child: Text(
                    'LiveMask v0.1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.items});
  final List<_SettingItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(item.icon, size: 20, color: AppColors.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.badgeColor!.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusXs),
                          border: Border.all(
                              color: item.badgeColor!.withOpacity(0.2)),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: item.badgeColor,
                          ),
                        ),
                      ),
                    if (item.value != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.value!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  final String? value;
  final String? badge;
  final Color? badgeColor;

  const _SettingItem({
    required this.icon,
    required this.label,
    this.value,
    this.badge,
    this.badgeColor,
  });
}
