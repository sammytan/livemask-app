import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/remote_config.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../providers/config_providers.dart';
import '../providers/node_providers.dart';
import '../models/node_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../widgets/livemask_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/error_banner.dart';

/// Home / Connect screen matching Atoms design v2.
///
/// Shows connection state, selected node, primary action, metrics.
/// VPN native runtime is NOT implemented — this is the UI preparation.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(configStateProvider);
    final authState = ref.watch(authStateProvider);
    final nodeListState = ref.watch(nodeListStateProvider);
    final recommendedState = ref.watch(recommendedNodeStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Top bar with logo + plan badge + settings
          PageHeader(
            title: 'LiveMask',
            actions: [
              if (authState.user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Chip(
                    avatar: Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    label: Text(
                      authState.user!.email,
                      style: const TextStyle(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                tooltip: 'Settings',
                onPressed: () => onNavigate('/profile'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Connection Status area (VPN-native, show as disconnected)
                  _ConnectionStatusDisplay(status: 'disconnected'),

                  const SizedBox(height: 24),

                  // Node selection cards
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _NodeCard(
                        icon: Icons.star,
                        label: 'Recommended',
                        subtitle: recommendedState.hasData
                            ? '${recommendedState.nodes.length} node${recommendedState.nodes.length == 1 ? '' : 's'}'
                            : 'Tap to load',
                        onTap: () => onNavigate('/nodes/recommended'),
                      ),
                      _NodeCard(
                        icon: Icons.dns_outlined,
                        label: 'All Nodes',
                        subtitle: nodeListState.hasData
                            ? '${nodeListState.nodes.length} node${nodeListState.nodes.length == 1 ? '' : 's'}'
                            : 'Tap to load',
                        onTap: () => onNavigate('/nodes'),
                      ),
                    ],
                  ),

                  // Error for config
                  if (configState.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    ErrorBanner(
                      title: 'Config error',
                      message: configState.errorMessage,
                      type: BannerType.warning,
                      actions: [
                        TextButton(
                          onPressed: () =>
                              ref.read(configStateProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Config state info
                  Text(
                    _configStatusLabel(configState.status),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  if (configState.hasValidConfig) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Config v${configState.configVersion}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _configStatusLabel(RemoteConfigStatus status) {
    switch (status) {
      case RemoteConfigStatus.current:
        return 'Configuration is up to date';
      case RemoteConfigStatus.stale:
        return 'Configuration is stale';
      case RemoteConfigStatus.fallback:
        return 'Using cached configuration';
      case RemoteConfigStatus.invalid:
        return 'Using cached configuration';
      case RemoteConfigStatus.degraded:
        return 'Using built-in defaults';
      case RemoteConfigStatus.none:
        return 'Loading configuration...';
    }
  }
}

/// Connection status display matching Atoms design's ConnectionStatusDisplay.
class _ConnectionStatusDisplay extends StatelessWidget {
  const _ConnectionStatusDisplay({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color iconColor, IconData icon, String label,
          String desc) = switch (status) {
      'disconnected' => (
        AppColors.muted.withOpacity(0.1),
        AppColors.muted,
        Icons.shield_outlined,
        'Disconnected',
        'Your connection is not protected.',
      ),
      'connecting' => (
        AppColors.primaryLight,
        AppColors.primary,
        Icons.sync,
        'Connecting',
        'Finding the best secure route...',
      ),
      'connected' => (
        Color(0xFFF0FDF4),
        AppColors.success,
        Icons.shield,
        'Connected',
        'Your connection is protected.',
      ),
      'degraded' => (
        AppColors.warningBg,
        AppColors.warning,
        Icons.warning_amber_rounded,
        'Degraded',
        'This node is slower than usual.',
      ),
      _ => (
        AppColors.dangerBg,
        AppColors.danger,
        Icons.shield_outlined,
        'Failed',
        'We could not connect to this node.',
      ),
    };

    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, size: 56, color: iconColor),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

/// Small card for quick navigation to node pages.
class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 150,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 28, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
