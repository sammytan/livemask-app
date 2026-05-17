import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node_models.dart';
import '../providers/node_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/livemask_widgets.dart';
import '../widgets/error_banner.dart';

/// Nodes screen matching Atoms design v2.
///
/// Shows recommended node section, search, region filter, favorites,
/// and full node list with status indicators.
class NodesScreen extends ConsumerStatefulWidget {
  const NodesScreen({super.key, required this.onNavigate});

  final void Function(String path) onNavigate;

  @override
  ConsumerState<NodesScreen> createState() => _NodesScreenState();
}

class _NodesScreenState extends ConsumerState<NodesScreen> {
  final _searchController = TextEditingController();
  String _activeRegion = 'All';
  bool _showFavorites = false;
  final Set<String> _favoriteIds = {};

  static const _regions = [
    'All',
    'Asia Pacific',
    'Europe',
    'North America',
    'South America',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNodes());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNodes() async {
    final state = ref.read(nodeListStateProvider);
    if (!state.hasData) {
      await ref.read(nodeListStateProvider.notifier).loadCached();
    }
  }

  Future<void> _refresh() async {
    await ref.read(nodeListStateProvider.notifier).refresh();
  }

  void _toggleFavorite(String nodeId) {
    setState(() {
      if (_favoriteIds.contains(nodeId)) {
        _favoriteIds.remove(nodeId);
      } else {
        _favoriteIds.add(nodeId);
      }
    });
  }

  String _extractRegion(String nodeName) {
    if (nodeName.contains('US East') || nodeName.contains('US West') ||
        nodeName.contains('North America')) return 'North America';
    if (nodeName.contains('EU') || nodeName.contains('Europe') ||
        nodeName.contains('Frankfurt') || nodeName.contains('Warsaw')) return 'Europe';
    if (nodeName.contains('Asia') || nodeName.contains('Tokyo') ||
        nodeName.contains('Singapore')) return 'Asia Pacific';
    if (nodeName.contains('South America') || nodeName.contains('São Paulo')) return 'South America';
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeListStateProvider);
    final theme = Theme.of(context);

    // Filter nodes
    final allNodes = state.nodes;
    final filtered = allNodes.where((n) {
      final matchesSearch = _searchController.text.isEmpty ||
          n.nodeName.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesRegion = _activeRegion == 'All' ||
          _extractRegion(n.nodeName) == _activeRegion;
      return matchesSearch && matchesRegion;
    }).toList();

    // Find best healthy node for recommendation
    final recommended = allNodes
        .where((n) => !n.degraded && n.isOnline)
        .fold<NodeInfo?>(null, (best, n) {
      if (best == null || n.loadScore < best.loadScore) return n;
      return best;
    });

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Nodes',
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
                            tooltip: 'Refresh',
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Search
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search city, region, or country...',
                        prefixIcon:
                            const Icon(Icons.search, size: 18, color: AppColors.muted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // Region filters
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _regions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final region = _regions[index];
                          final isActive = _activeRegion == region;
                          return FilterChip(
                            label: Text(region, style: const TextStyle(fontSize: 12)),
                            selected: isActive,
                            onSelected: (_) {
                              setState(() => _activeRegion = region);
                            },
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isActive ? Colors.white : null,
                              fontSize: 12,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: state.isLoading && !state.hasData
                ? const Center(child: CircularProgressIndicator())
                : !state.hasData && state.hasError
                    ? EmptyState(
                        icon: Icons.cloud_off,
                        title: 'Could not load nodes',
                        message: state.errorMessage,
                        action: _refresh,
                        actionLabel: 'Retry',
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Stale indicator
                            if (state.isFromCache)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ErrorBanner.warning(
                                  'Showing cached nodes',
                                ),
                              ),

                            // Error when has stale data
                            if (state.hasError && state.isFromCache)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ErrorBanner.danger(
                                  'Refresh failed',
                                  message: state.errorMessage,
                                ),
                              ),

                            // Recommended node section
                            if (recommended != null &&
                                _activeRegion == 'All' &&
                                _searchController.text.isEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _NodeCard(
                                node: recommended,
                                isSelected: false,
                                isFavorite:
                                    _favoriteIds.contains(recommended.nodeId),
                                onTap: () {},
                                onToggleFavorite: () =>
                                    _toggleFavorite(recommended.nodeId),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Favorites section
                            if (_favoriteIds.isNotEmpty &&
                                _searchController.text.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Favorites',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              ...filtered
                                  .where(
                                      (n) => _favoriteIds.contains(n.nodeId))
                                  .map((node) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: _NodeCard(
                                          node: node,
                                          isSelected: false,
                                          isFavorite: true,
                                          onTap: () {},
                                          onToggleFavorite: () =>
                                              _toggleFavorite(node.nodeId),
                                        ),
                                      )),
                              const SizedBox(height: 8),
                            ],

                            // All nodes header
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'All Nodes (${filtered.length})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),

                            // Node list
                            ...filtered.map((node) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _NodeCard(
                                    node: node,
                                    isSelected: false,
                                    isFavorite:
                                        _favoriteIds.contains(node.nodeId),
                                    onTap: () {},
                                    onToggleFavorite: () =>
                                        _toggleFavorite(node.nodeId),
                                  ),
                                )),

                            if (filtered.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    'No nodes match your search.',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Node card matching Atoms design v2 NodeCard component.
class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    this.onToggleFavorite,
  });

  final NodeInfo node;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color statusDot;
    final String statusLabel;
    if (node.isOffline) {
      statusDot = AppColors.muted;
      statusLabel = 'Offline';
    } else if (node.isDegraded) {
      statusDot = AppColors.warning;
      statusLabel = 'Degraded';
    } else {
      statusDot = AppColors.success;
      statusLabel = 'Healthy';
    }

    return LiveMaskCard(
      selected: isSelected,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Globe icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Icon(
              Icons.language,
              size: 20,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),

          // Node info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      node.nodeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _metricText(
                        '${node.loadScore.toStringAsFixed(2)} load'),
                    const SizedBox(width: 8),
                    _metricText(
                        '${node.cpuUsage.toStringAsFixed(0)}% CPU'),
                    if (node.activeConnections > 0) ...[
                      const SizedBox(width: 8),
                      _metricText(
                          '${_formatCount(node.activeConnections)} conn'),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Status + favorite
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: statusDot,
                    ),
                  ),
                ],
              ),
              if (node.isDegraded) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Not recommended',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
              if (onToggleFavorite != null) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: onToggleFavorite,
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    size: 18,
                    color: isFavorite ? AppColors.warning : AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: AppColors.muted,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
