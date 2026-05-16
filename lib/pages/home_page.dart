import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/remote_config.dart';
import '../providers/auth_providers.dart';
import '../providers/config_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(configStateProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveMask'),
        actions: [
          if (authState.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  authState.user!.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh config',
            onPressed: () {
              ref.read(configStateProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Config debug',
            onPressed: () {
              Navigator.of(context).pushNamed('/config-debug');
            },
          ),
          if (authState.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
              },
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 80,
                color: _statusColor(configState.status),
              ),
              const SizedBox(height: 24),
              Text(
                _statusLabel(configState.status),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              // Auth info
              if (authState.isAuthenticated && authState.user != null) ...[
                const SizedBox(height: 12),
                Chip(
                  avatar: const Icon(Icons.person, size: 16),
                  label: Text(authState.user!.email),
                ),
                Text(
                  'Roles: ${authState.user!.roles.join(", ")}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],

              // User summary area when logged in
              if (authState.isAuthenticated && authState.user != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow(
                            context,
                            'User ID',
                            authState.user!.userId,
                          ),
                          _infoRow(
                            context,
                            'Subscription',
                            authState.user!.subscriptionStatus ?? 'none',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Error for config
              if (configState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    configState.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orangeAccent,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              if (configState.hasValidConfig)
                Text(
                  'Config v${configState.configVersion}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(RemoteConfigStatus status) {
    switch (status) {
      case RemoteConfigStatus.current:
        return Colors.green;
      case RemoteConfigStatus.stale:
        return Colors.amber;
      case RemoteConfigStatus.fallback:
      case RemoteConfigStatus.invalid:
        return Colors.orange;
      case RemoteConfigStatus.degraded:
        return Colors.redAccent;
      case RemoteConfigStatus.none:
        return Colors.grey;
    }
  }

  String _statusLabel(RemoteConfigStatus status) {
    switch (status) {
      case RemoteConfigStatus.current:
        return 'Config current';
      case RemoteConfigStatus.stale:
        return 'Config stale';
      case RemoteConfigStatus.fallback:
        return 'Using cached config\n(Backend unavailable)';
      case RemoteConfigStatus.invalid:
        return 'Using cached config\n(Remote config invalid)';
      case RemoteConfigStatus.degraded:
        return 'Degraded mode\n(Using built-in defaults)';
      case RemoteConfigStatus.none:
        return 'Loading...';
    }
  }
}
