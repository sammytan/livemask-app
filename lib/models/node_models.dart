/// Node-related data models for the Backend nodes API contract.
///
/// Only public safe fields are exposed. Sensitive fields such as
/// `ip_address`, `node_secret`, `agent_version` are never mapped.

/// A single node in the Backend infrastructure.
class NodeInfo {
  const NodeInfo({
    required this.nodeId,
    required this.nodeName,
    required this.status,
    required this.loadScore,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.activeConnections,
    required this.degraded,
    this.lastHeartbeatAt,
  });

  factory NodeInfo.fromJson(Map<String, dynamic> json) {
    // Backend JSON uses "id" as primary key (NodePublic.id).
    // Some fixtures may use "node_id" — support both for compatibility.
    final rawId = json['id'] ?? json['node_id'];
    return NodeInfo(
      nodeId: rawId is String ? rawId : rawId?.toString() ?? '',
      nodeName: json['node_name'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      loadScore: (json['load_score'] as num?)?.toDouble() ?? 0.0,
      cpuUsage: (json['cpu_usage'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (json['memory_usage'] as num?)?.toDouble() ?? 0.0,
      activeConnections: json['active_connections'] as int? ?? 0,
      degraded: json['degraded'] as bool? ?? false,
      lastHeartbeatAt: json['last_heartbeat_at'] as String?,
    );
  }

  final String nodeId;
  final String nodeName;
  final String status;
  final double loadScore;
  final double cpuUsage;
  final double memoryUsage;
  final int activeConnections;
  final bool degraded;
  final String? lastHeartbeatAt;

  Map<String, dynamic> toJson() => {
        'node_id': nodeId,
        'node_name': nodeName,
        'status': status,
        'load_score': loadScore,
        'cpu_usage': cpuUsage,
        'memory_usage': memoryUsage,
        'active_connections': activeConnections,
        'degraded': degraded,
        if (lastHeartbeatAt != null) 'last_heartbeat_at': lastHeartbeatAt,
      };

  /// Whether the node is in a usable state.
  bool get isOnline => status == 'online' && !degraded;

  /// Whether the node is reachable but degraded.
  bool get isDegraded => status == 'online' && degraded;

  /// Whether the node is offline entirely.
  bool get isOffline => status == 'offline';

  /// Human-readable label for node status.
  String get statusLabel {
    if (isOffline) return 'Offline';
    if (isDegraded) return 'Degraded';
    if (isOnline) return 'Online';
    return status;
  }

  /// Returns a compact one-line status summary.
  String get summary =>
      '$nodeName — ${statusLabel}, load $loadScore, ${cpuUsage.toStringAsFixed(1)}% CPU';

  @override
  String toString() =>
      'NodeInfo(nodeId=$nodeId, name=$nodeName, status=$status, '
      'degraded=$degraded, load=$loadScore)';
}

/// Response wrapper for `GET /api/v1/nodes`.
class NodeListResponse {
  const NodeListResponse({
    required this.nodes,
    this.total,
  });

  factory NodeListResponse.fromJson(Map<String, dynamic> json) {
    final nodesList = json['nodes'] as List<dynamic>? ?? [];
    return NodeListResponse(
      nodes: nodesList
          .map((e) =>
              NodeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int?,
    );
  }

  final List<NodeInfo> nodes;
  final int? total;

  int get count => nodes.length;

  /// Filter out offline nodes.
  List<NodeInfo> get onlineNodes =>
      nodes.where((n) => !n.isOffline).toList();

  /// Filter nodes that are degraded.
  List<NodeInfo> get degradedNodes =>
      nodes.where((n) => n.isDegraded).toList();

  /// Nodes that are fully healthy (online, not degraded).
  List<NodeInfo> get healthyNodes =>
      nodes.where((n) => n.isOnline).toList();
}

/// Response wrapper for `GET /api/v1/nodes/recommended`.
class RecommendedNodeResponse {
  const RecommendedNodeResponse({
    required this.nodes,
  });

  factory RecommendedNodeResponse.fromJson(Map<String, dynamic> json) {
    final nodesRaw = json['nodes'] as List<dynamic>?;
    if (nodesRaw != null && nodesRaw.isNotEmpty) {
      return RecommendedNodeResponse(
        nodes: nodesRaw
            .map((e) =>
                NodeInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    // Single node response fallback (Backend uses "id" or "node_id").
    if (json.containsKey('id') || json.containsKey('node_id')) {
      return RecommendedNodeResponse(
        nodes: [NodeInfo.fromJson(json)],
      );
    }
    return RecommendedNodeResponse(nodes: const []);
  }

  final List<NodeInfo> nodes;

  bool get isEmpty => nodes.isEmpty;
  bool get hasSingle => nodes.length == 1;
  NodeInfo? get primary => nodes.isNotEmpty ? nodes.first : null;
}

/// State container for node data at the provider layer.
class NodeListState {
  const NodeListState({
    this.nodes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdatedAt,
    this.isFromCache = false,
  });

  final List<NodeInfo> nodes;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final bool isFromCache;

  bool get hasData => nodes.isNotEmpty;
  bool get hasError => errorMessage != null;

  NodeListState copyWith({
    List<NodeInfo>? nodes,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdatedAt,
    bool? isFromCache,
    bool clearError = false,
  }) {
    return NodeListState(
      nodes: nodes ?? this.nodes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// State container for recommended node data.
class RecommendedNodeState {
  const RecommendedNodeState({
    this.nodes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdatedAt,
    this.isFromCache = false,
  });

  final List<NodeInfo> nodes;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final bool isFromCache;

  bool get isEmpty => nodes.isEmpty;
  bool get hasData => nodes.isNotEmpty;
  bool get hasError => errorMessage != null;
  NodeInfo? get primary => nodes.isNotEmpty ? nodes.first : null;

  RecommendedNodeState copyWith({
    List<NodeInfo>? nodes,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdatedAt,
    bool? isFromCache,
    bool clearError = false,
  }) {
    return RecommendedNodeState(
      nodes: nodes ?? this.nodes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}
