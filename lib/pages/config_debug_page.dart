import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/remote_config.dart';
import '../providers/config_providers.dart';

/// Debug / settings page showing detailed remote config status.
///
/// Useful for QA, support, and developer troubleshooting.
class ConfigDebugPage extends ConsumerWidget {
  const ConfigDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(configStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Config Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh config',
            onPressed: () {
              ref.read(configStateProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(configState: configState),
          const SizedBox(height: 16),
          _PayloadCard(configState: configState),
          const SizedBox(height: 16),
          _ActionsCard(ref: ref),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.configState});

  final RemoteConfigState configState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: theme.textTheme.titleMedium),
            const Divider(),
            _row('Config Status', _statusLabel(configState.status)),
            _row('Config Version', '${configState.configVersion}'),
            _row(
              'Has Valid Config',
              configState.hasValidConfig ? 'Yes' : 'No',
            ),
            _row(
              'Using Defaults',
              configState.isUsingDefaults ? 'Yes' : 'No',
            ),
            if (configState.lastUpdatedAt != null)
              _row(
                'Last Updated',
                _formatDateTime(configState.lastUpdatedAt!),
              ),
            if (configState.errorMessage != null)
              _row('Error', configState.errorMessage!, isError: true),
            if (configState.response != null) ...[
              const SizedBox(height: 8),
              _row('Config Key', configState.response!.configKey),
              _row('Schema Version', configState.response!.schemaVersion),
              _row('Hash', configState.response!.configHash),
              if (configState.response!.publishedAt != null)
                _row('Published At', configState.response!.publishedAt!),
              if (configState.response!.fallbackAction != null)
                _row(
                  'Fallback Action',
                  configState.response!.fallbackAction!,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.redAccent : null,
                fontFamily: isError ? null : 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _statusLabel(RemoteConfigStatus status) {
    switch (status) {
      case RemoteConfigStatus.current:
        return 'current';
      case RemoteConfigStatus.stale:
        return 'stale';
      case RemoteConfigStatus.fallback:
        return 'fallback';
      case RemoteConfigStatus.invalid:
        return 'invalid';
      case RemoteConfigStatus.degraded:
        return 'degraded';
      case RemoteConfigStatus.none:
        return 'none';
    }
  }
}

class _PayloadCard extends StatelessWidget {
  const _PayloadCard({required this.configState});

  final RemoteConfigState configState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payload (connection)', style: theme.textTheme.titleMedium),
            const Divider(),
            _field('Recommendation TTL',
                '${configState.payload['connection']?['recommendation_ttl_seconds'] ?? 'N/A'} s'),
            _field('Fallback Max Attempts',
                '${configState.payload['connection']?['fallback_max_attempts'] ?? 'N/A'}'),
            _field('Quick Feedback',
                '${configState.payload['feature_flags']?['quick_feedback_enabled'] ?? 'N/A'}'),
            _field('Connection Quality Report',
                '${configState.payload['feature_flags']?['connection_quality_report_enabled'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: theme.textTheme.titleMedium),
            const Divider(),
            FilledButton.icon(
              onPressed: () {
                ref.read(configStateProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Manual Refresh'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(configStateProvider.notifier).loadCached();
              },
              icon: const Icon(Icons.cached),
              label: const Text('Reload from Cache'),
            ),
          ],
        ),
      ),
    );
  }
}
