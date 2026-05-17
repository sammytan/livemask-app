import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/remote_config.dart';
import '../providers/config_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Developer/debug screen for remote config inspection.
///
/// NOT intended as a regular user entry — this is a development tool.
class ConfigDebugScreen extends ConsumerWidget {
  const ConfigDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(configStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Config Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () =>
                ref.read(configStateProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(context: context, state: configState),
          const SizedBox(height: 16),
          if (configState.response != null)
            _PayloadCard(context: context, response: configState.response!),
        ],
      ),
    );
  }

  Widget _StatusCard({
    required BuildContext context,
    required RemoteConfigState state,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppConstants.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Config Status',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _Row('Status', state.status.name),
          if (state.configVersion > 0)
            _Row('Version', state.configVersion.toString()),
          if (state.lastUpdatedAt != null)
            _Row('Last Updated', state.lastUpdatedAt.toString()),
          if (state.errorMessage != null)
            _Row('Error', state.errorMessage!, isError: true),
          if (state.response != null) ...[
            const Divider(height: 16),
            _Row('Config Key', state.response!.configKey),
            _Row('Schema', state.response!.schemaVersion),
            _Row('Hash', state.response!.configHash.length > 30
                ? '${state.response!.configHash.substring(0, 30)}...'
                : state.response!.configHash),
            if (state.response!.publishedAt != null)
              _Row('Published', state.response!.publishedAt!),
          ],
        ],
      ),
    );
  }

  Widget _PayloadCard({
    required BuildContext context,
    required RemoteConfigResponse response,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppConstants.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payload',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _prettyPrint(response.payload),
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _Row(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isError ? AppColors.danger : AppColors.ink,
                fontWeight: isError ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyPrint(Map<String, dynamic> map) {
    try {
      return _formatMap(map, 0);
    } catch (_) {
      return map.toString();
    }
  }

  String _formatMap(Map<String, dynamic> map, int indent) {
    final buf = StringBuffer();
    final prefix = '  ' * indent;
    buf.write('{\n');
    for (final entry in map.entries) {
      buf.write('$prefix  "${entry.key}": ');
      if (entry.value is Map) {
        buf.write(_formatMap(entry.value as Map<String, dynamic>, indent + 1));
      } else if (entry.value is String) {
        buf.write('"${entry.value}"');
      } else {
        buf.write('${entry.value}');
      }
      buf.write(',\n');
    }
    buf.write('$prefix}');
    return buf.toString();
  }
}
