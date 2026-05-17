import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/billing_models.dart';
import '../providers/auth_providers.dart';
import '../providers/billing_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';

/// Profile / Settings screen with devices section.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDevices());
  }

  Future<void> _refreshDevices() async {
    if (!mounted) return;
    await ref.read(devicesStateProvider.notifier).refresh();
  }

  Future<void> _handleAddDevice() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Device'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Device name',
            hintText: 'e.g. Sammy iPhone',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || !mounted) return;

    // Determine platform from user agent or environment.
    final platform = Theme.of(context).platform == TargetPlatform.iOS
        ? 'ios'
        : Theme.of(context).platform == TargetPlatform.android
            ? 'android'
            : Theme.of(context).platform == TargetPlatform.macOS
                ? 'macos'
                : 'unknown';
    const appVersion = '0.1.0';

    final error =
        await ref.read(devicesStateProvider.notifier).addDevice(
              result,
              platform,
              appVersion,
            );

    if (!mounted) return;

    if (error != null) {
      if (error.contains('DEVICE_LIMIT_EXCEEDED') ||
          error.contains('409') ||
          error.contains('Device limit')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device added successfully')),
      );
    }
  }

  Future<void> _handleRevokeDevice(DeviceInfo device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Device'),
        content: Text(
            'Remove "${device.deviceName}" from your devices?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final error = await ref
        .read(devicesStateProvider.notifier)
        .revokeDevice(device.deviceId);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device revoked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final devicesState = ref.watch(devicesStateProvider);
    final theme = Theme.of(context);

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

                // Devices section
                _SectionTitle('My Devices'),
                _DevicesSection(
                  devicesState: devicesState,
                  onRefresh: _refreshDevices,
                  onAddDevice: _handleAddDevice,
                  onRevokeDevice: _handleRevokeDevice,
                ),

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
                    value: theme.brightness == Brightness.dark ? 'On' : 'Off',
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

                // Sign Out
                if (authState.isAuthenticated)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        widget.onLogout();
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side:
                            BorderSide(color: AppColors.danger.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // App version
                Center(
                  child: Text(
                    'LiveMask v0.1.0',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
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

/// Devices section with list, usage counter, and add/revoke actions.
class _DevicesSection extends StatelessWidget {
  const _DevicesSection({
    required this.devicesState,
    required this.onRefresh,
    required this.onAddDevice,
    required this.onRevokeDevice,
  });

  final DevicesState devicesState;
  final VoidCallback onRefresh;
  final VoidCallback onAddDevice;
  final void Function(DeviceInfo) onRevokeDevice;

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
        children: [
          // Device usage header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.devices_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${devicesState.deviceUsed}/${devicesState.deviceLimit} devices',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (devicesState.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  InkWell(
                    onTap: onRefresh,
                    child: Icon(Icons.refresh, size: 18, color: AppColors.muted),
                  ),
              ],
            ),
          ),

          // Capacity warning
          if (!devicesState.hasCapacity && devicesState.hasData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Device limit reached. Remove a device or upgrade your plan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Stale banner
          if (devicesState.isFromCache)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Showing cached data',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ),

          // Device list
          if (devicesState.isLoading && !devicesState.hasData)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (devicesState.hasError && !devicesState.hasData)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorBanner.danger(
                'Could not load devices',
                message: devicesState.errorMessage,
                actions: [
                  TextButton(
                    onPressed: onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (devicesState.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.devices_outlined,
                title: 'No devices registered',
                message: 'Register this device to start using LiveMask.',
              ),
            )
          else
            ...devicesState.devices.map((device) => _DeviceRow(
                  device: device,
                  onRevoke: () => onRevokeDevice(device),
                )),

          // Add device button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: devicesState.hasCapacity ? onAddDevice : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Device'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single device row.
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.onRevoke});

  final DeviceInfo device;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(device.platformIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.deviceName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (device.trusted)
                      Icon(Icons.verified_outlined,
                          size: 14, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.platformLabel}${device.appVersion != null ? ' · v${device.appVersion}' : ''}',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onRevoke,
            child: Icon(Icons.remove_circle_outline,
                size: 20, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

// ---- Shared helpers (copied from existing ProfileScreen) ----

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
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
