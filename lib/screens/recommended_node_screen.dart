import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node_models.dart';
import '../providers/node_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../widgets/livemask_widgets.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';

/// Recommended node page - uses only /api/v1/nodes/recommended.
class RecommendedNodeScreen extends ConsumerStatefulWidget {
  const RecommendedNodeScreen({super.key});

  @override
  ConsumerState<RecommendedNodeScreen> createState() =>
      _RecommendedNodeScreenState();
}

class _RecommendedNodeScreenState extends ConsumerState<RecommendedNodeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final state = ref.read(recommendedNodeStateProvider);
    if (!state.hasData) {
      await ref.read(recommendedNodeStateProvider.notifier).loadCached();
    }
  }

  Future<void> _refresh() async {
    await ref.read(recommendedNodeStateProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendedNodeStateProvider);
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
                        'Recommended Node',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (state.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _refresh,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: _buildBody(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RecommendedNodeState state, ThemeData theme) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasData && state.hasError) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Could not get recommendations',
        message: state.errorMessage,
        action: _refresh,
        actionLabel: 'Retry',
      );
    }

    if (!state.hasData) {
      return EmptyState(
        icon: Icons.emoji_objects_outlined,
        title: 'No recommendations available',
        message:
            'There are no recommended nodes right now.\nPlease check back later.',
        action: _refresh,
        actionLabel: 'Refresh',
      );
    }

    final nodes = state.nodes;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.isFromCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ErrorBanner.warning(
                'Showing cached recommendation',
                message: 'Pull to refresh.',
              ),
            ),

          if (state.hasError && state.isFromCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ErrorBanner.danger(
                'Refresh failed',
                message: state.errorMessage,
              ),
            ),

          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Recommended node${nodes.length == 1 ? '' : 's'}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'These nodes are selected for optimal performance.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),

          // Recommended nodes
          ...nodes.map((node) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecommendedNodeCard(node: node),
              )),

          // All degraded warning
          if (nodes.isNotEmpty && nodes.every((n) => n.isDegraded))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Card(
                color: AppColors.warningBg,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recommended nodes are degraded. Browse the full '
                          'list to find a healthy node.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.warning.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendedNodeCard extends StatelessWidget {
  const _RecommendedNodeCard({required this.node});

  final NodeInfo node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDegraded = node.isDegraded;
    final statusColor = isDegraded ? AppColors.warning : AppColors.success;

    return LiveMaskCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  node.nodeName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isDegraded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Degraded',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _metricBlock(theme, 'Load', node.loadScore.toStringAsFixed(2)),
              _metricBlock(
                  theme, 'CPU', '${node.cpuUsage.toStringAsFixed(0)}%'),
              _metricBlock(
                  theme, 'Memory', '${node.memoryUsage.toStringAsFixed(0)}%'),
              _metricBlock(theme, 'Connections',
                  _formatCount(node.activeConnections)),
            ],
          ),
          if (isDegraded) ...[
            const SizedBox(height: 12),
            Container(
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
                      'This node is currently degraded and is not recommended '
                      'for connections.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricBlock(ThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
