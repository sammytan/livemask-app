import '../models/node_models.dart';
import 'node_api_client.dart';
import 'real_node_api_client.dart';

/// Mock [NodeApiClient] used when the Backend is not ready.
///
/// Returns realistic simulated node data for development and testing.
class MockNodeApiClient implements NodeApiClient {
  MockNodeApiClient();

  static final List<NodeInfo> _mockNodes = [
    NodeInfo(
      nodeId: 'node-001',
      nodeName: 'US East (Virginia)',
      status: 'online',
      loadScore: 0.42,
      cpuUsage: 34.5,
      memoryUsage: 55.2,
      activeConnections: 1423,
      degraded: false,
      lastHeartbeatAt: '2026-05-17T10:00:00Z',
    ),
    NodeInfo(
      nodeId: 'node-002',
      nodeName: 'US West (Oregon)',
      status: 'online',
      loadScore: 0.38,
      cpuUsage: 28.1,
      memoryUsage: 42.7,
      activeConnections: 987,
      degraded: false,
      lastHeartbeatAt: '2026-05-17T10:00:00Z',
    ),
    NodeInfo(
      nodeId: 'node-003',
      nodeName: 'EU West (Frankfurt)',
      status: 'online',
      loadScore: 0.55,
      cpuUsage: 45.2,
      memoryUsage: 60.1,
      activeConnections: 2156,
      degraded: false,
      lastHeartbeatAt: '2026-05-17T09:59:00Z',
    ),
    NodeInfo(
      nodeId: 'node-004',
      nodeName: 'EU Central (Warsaw)',
      status: 'online',
      loadScore: 0.31,
      cpuUsage: 22.8,
      memoryUsage: 38.4,
      activeConnections: 756,
      degraded: false,
      lastHeartbeatAt: '2026-05-17T10:00:00Z',
    ),
    NodeInfo(
      nodeId: 'node-005',
      nodeName: 'Asia East (Tokyo)',
      status: 'online',
      loadScore: 0.61,
      cpuUsage: 51.3,
      memoryUsage: 68.9,
      activeConnections: 3120,
      degraded: true,
      lastHeartbeatAt: '2026-05-17T09:55:00Z',
    ),
    NodeInfo(
      nodeId: 'node-006',
      nodeName: 'Asia SE (Singapore)',
      status: 'online',
      loadScore: 0.45,
      cpuUsage: 36.7,
      memoryUsage: 50.3,
      activeConnections: 1654,
      degraded: false,
      lastHeartbeatAt: '2026-05-17T10:00:00Z',
    ),
    NodeInfo(
      nodeId: 'node-007',
      nodeName: 'Oceania (Sydney)',
      status: 'offline',
      loadScore: 0.0,
      cpuUsage: 0.0,
      memoryUsage: 0.0,
      activeConnections: 0,
      degraded: false,
      lastHeartbeatAt: '2026-05-17T08:00:00Z',
    ),
    NodeInfo(
      nodeId: 'node-008',
      nodeName: 'South America (São Paulo)',
      status: 'online',
      loadScore: 0.29,
      cpuUsage: 19.4,
      memoryUsage: 32.1,
      activeConnections: 534,
      degraded: false,
      lastHeartbeatAt: '2026-05-17T10:00:00Z',
    ),
  ];

  static final List<NodeInfo> _recommended = _mockNodes
      .where((n) => !n.degraded && n.isOnline && n.loadScore < 0.50)
      .toList()
    ..sort((a, b) => a.loadScore.compareTo(b.loadScore));

  @override
  Future<NodeListResponse> fetchNodes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return NodeListResponse(
      nodes: _mockNodes,
      total: _mockNodes.length,
    );
  }

  @override
  Future<RecommendedNodeResponse> fetchRecommended() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return RecommendedNodeResponse(nodes: _recommended);
  }
}
