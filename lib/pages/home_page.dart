import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/remote_config.dart';
import '../providers/config_providers.dart';
import 'config_debug_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(configStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveMask'),
        actions: [
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConfigDebugPage(),
                ),
              );
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
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
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
