import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/models/node_models.dart';

void main() {
  group('NodeInfo', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'node_id': 'node-001',
        'node_name': 'US East (Virginia)',
        'status': 'online',
        'load_score': 0.42,
        'cpu_usage': 34.5,
        'memory_usage': 55.2,
        'active_connections': 1423,
        'degraded': false,
        'last_heartbeat_at': '2026-05-17T10:00:00Z',
      };

      final node = NodeInfo.fromJson(json);

      expect(node.nodeId, 'node-001');
      expect(node.nodeName, 'US East (Virginia)');
      expect(node.status, 'online');
      expect(node.loadScore, 0.42);
      expect(node.cpuUsage, 34.5);
      expect(node.memoryUsage, 55.2);
      expect(node.activeConnections, 1423);
      expect(node.degraded, false);
      expect(node.lastHeartbeatAt, '2026-05-17T10:00:00Z');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'node_id': 'node-002',
        'node_name': 'Test Node',
        'status': 'online',
        'load_score': 0.5,
        'cpu_usage': 50.0,
        'memory_usage': 60.0,
        'active_connections': 100,
        'degraded': false,
      };

      final node = NodeInfo.fromJson(json);
      expect(node.nodeId, 'node-002');
      expect(node.lastHeartbeatAt, null);
    });

    test('fromJson handles empty/missing fields with defaults', () {
      final node = NodeInfo.fromJson(<String, dynamic>{});
      expect(node.nodeId, '');
      expect(node.nodeName, '');
      expect(node.status, 'unknown');
      expect(node.loadScore, 0.0);
      expect(node.cpuUsage, 0.0);
      expect(node.memoryUsage, 0.0);
      expect(node.activeConnections, 0);
      expect(node.degraded, false);
    });

    test('isOnline returns true only when status=online and not degraded', () {
      expect(
        NodeInfo(
          nodeId: 'a',
          nodeName: 'A',
          status: 'online',
          loadScore: 0.5,
          cpuUsage: 50,
          memoryUsage: 50,
          activeConnections: 0,
          degraded: false,
        ).isOnline,
        true,
      );
      expect(
        NodeInfo(
          nodeId: 'a',
          nodeName: 'A',
          status: 'online',
          loadScore: 0.5,
          cpuUsage: 50,
          memoryUsage: 50,
          activeConnections: 0,
          degraded: true,
        ).isOnline,
        false,
      );
      expect(
        NodeInfo(
          nodeId: 'a',
          nodeName: 'A',
          status: 'offline',
          loadScore: 0.5,
          cpuUsage: 50,
          memoryUsage: 50,
          activeConnections: 0,
          degraded: false,
        ).isOnline,
        false,
      );
    });

    test('isDegraded returns true only when online and degraded', () {
      expect(
        NodeInfo(
          nodeId: 'a',
          nodeName: 'A',
          status: 'online',
          loadScore: 0.5,
          cpuUsage: 50,
          memoryUsage: 50,
          activeConnections: 0,
          degraded: true,
        ).isDegraded,
        true,
      );
      expect(
        NodeInfo(
          nodeId: 'a',
          nodeName: 'A',
          status: 'online',
          loadScore: 0.5,
          cpuUsage: 50,
          memoryUsage: 50,
          activeConnections: 0,
          degraded: false,
        ).isDegraded,
        false,
      );
    });

    test('toJson produces correct output', () {
      final node = NodeInfo(
        nodeId: 'n1',
        nodeName: 'Test',
        status: 'online',
        loadScore: 0.3,
        cpuUsage: 25.0,
        memoryUsage: 50.0,
        activeConnections: 500,
        degraded: false,
        lastHeartbeatAt: '2026-01-01T00:00:00Z',
      );

      final json = node.toJson();
      expect(json['node_id'], 'n1');
      expect(json['node_name'], 'Test');
      expect(json['status'], 'online');
      expect(json['load_score'], 0.3);
      expect(json['degraded'], false);
      expect(json['last_heartbeat_at'], '2026-01-01T00:00:00Z');
    });

    test('toJson omits null lastHeartbeatAt', () {
      final node = NodeInfo(
        nodeId: 'n2',
        nodeName: 'No Heartbeat',
        status: 'offline',
        loadScore: 0.0,
        cpuUsage: 0.0,
        memoryUsage: 0.0,
        activeConnections: 0,
        degraded: false,
      );

      final json = node.toJson();
      expect(json.containsKey('last_heartbeat_at'), false);
    });

    test('statusLabel returns correct labels', () {
      final online = NodeInfo(
        nodeId: 'a',
        nodeName: 'A',
        status: 'online',
        loadScore: 0.5,
        cpuUsage: 50,
        memoryUsage: 50,
        activeConnections: 0,
        degraded: false,
      );
      expect(online.statusLabel, 'Online');

      final degraded = NodeInfo(
        nodeId: 'a',
        nodeName: 'A',
        status: 'online',
        loadScore: 0.5,
        cpuUsage: 50,
        memoryUsage: 50,
        activeConnections: 0,
        degraded: true,
      );
      expect(degraded.statusLabel, 'Degraded');

      final offline = NodeInfo(
        nodeId: 'a',
        nodeName: 'A',
        status: 'offline',
        loadScore: 0.5,
        cpuUsage: 50,
        memoryUsage: 50,
        activeConnections: 0,
        degraded: false,
      );
      expect(offline.statusLabel, 'Offline');
    });

    test('summary returns compact string', () {
      final node = NodeInfo(
        nodeId: 'n1',
        nodeName: 'US East',
        status: 'online',
        loadScore: 0.42,
        cpuUsage: 34.5,
        memoryUsage: 55.2,
        activeConnections: 1423,
        degraded: false,
      );
      expect(node.summary, contains('US East'));
      expect(node.summary, contains('Online'));
      expect(node.summary, contains('0.42'));
      expect(node.summary, contains('34.5%'));
    });
  });

  group('NodeListResponse', () {
    test('fromJson parses node list', () {
      final json = {
        'nodes': [
          {
            'node_id': 'n1',
            'node_name': 'Node 1',
            'status': 'online',
            'load_score': 0.5,
            'cpu_usage': 50,
            'memory_usage': 50,
            'active_connections': 100,
            'degraded': false,
          },
          {
            'node_id': 'n2',
            'node_name': 'Node 2',
            'status': 'offline',
            'load_score': 0.0,
            'cpu_usage': 0,
            'memory_usage': 0,
            'active_connections': 0,
            'degraded': false,
          },
        ],
        'total': 2,
      };

      final response = NodeListResponse.fromJson(json);
      expect(response.nodes.length, 2);
      expect(response.total, 2);
      expect(response.count, 2);
    });

    test('fromJson handles empty node list', () {
      final response = NodeListResponse.fromJson({'nodes': []});
      expect(response.nodes, isEmpty);
      expect(response.total, null);
    });

    test('fromJson handles null nodes field', () {
      final response = NodeListResponse.fromJson({});
      expect(response.nodes, isEmpty);
    });

    test('onlineNodes filters correctly', () {
      final response = NodeListResponse(
        nodes: [
          NodeInfo(
            nodeId: 'n1',
            nodeName: 'N1',
            status: 'online',
            loadScore: 0.5,
            cpuUsage: 50,
            memoryUsage: 50,
            activeConnections: 100,
            degraded: false,
          ),
          NodeInfo(
            nodeId: 'n2',
            nodeName: 'N2',
            status: 'offline',
            loadScore: 0,
            cpuUsage: 0,
            memoryUsage: 0,
            activeConnections: 0,
            degraded: false,
          ),
          NodeInfo(
            nodeId: 'n3',
            nodeName: 'N3',
            status: 'online',
            loadScore: 0.5,
            cpuUsage: 50,
            memoryUsage: 50,
            activeConnections: 100,
            degraded: true,
          ),
        ],
      );

      expect(response.onlineNodes.length, 2); // n1 (healthy) + n3 (degraded)
      expect(response.degradedNodes.length, 1); // n3 only
      expect(response.healthyNodes.length, 1); // n1 only
    });
  });

  group('RecommendedNodeResponse', () {
    test('fromJson parses nodes list', () {
      final json = {
        'nodes': [
          {
            'node_id': 'n1',
            'node_name': 'Node 1',
            'status': 'online',
            'load_score': 0.3,
            'cpu_usage': 30,
            'memory_usage': 40,
            'active_connections': 50,
            'degraded': false,
          },
        ],
      };

      final response = RecommendedNodeResponse.fromJson(json);
      expect(response.isEmpty, false);
      expect(response.hasSingle, true);
      expect(response.primary?.nodeId, 'n1');
    });

    test('fromJson handles single node object (fallback)', () {
      final json = {
        'node_id': 'n1',
        'node_name': 'Single Node',
        'status': 'online',
        'load_score': 0.3,
        'cpu_usage': 30,
        'memory_usage': 40,
        'active_connections': 50,
        'degraded': false,
      };

      final response = RecommendedNodeResponse.fromJson(json);
      expect(response.isEmpty, false);
      expect(response.primary?.nodeId, 'n1');
    });

    test('fromJson handles empty nodes', () {
      final response = RecommendedNodeResponse.fromJson({'nodes': []});
      expect(response.isEmpty, true);
      expect(response.primary, null);
    });

    test('fromJson handles missing nodes field', () {
      final response = RecommendedNodeResponse.fromJson({});
      expect(response.isEmpty, true);
    });
  });

  group('NodeListState', () {
    test('initial state has no data and no error', () {
      const state = NodeListState();
      expect(state.hasData, false);
      expect(state.hasError, false);
      expect(state.isLoading, false);
      expect(state.isFromCache, false);
    });

    test('copyWith updates fields correctly', () {
      const state = NodeListState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(updated.hasData, false);

      final cleared = updated.copyWith(clearError: true);
      // error was already null, so no change
      expect(cleared.hasError, false);
    });
  });

  group('RecommendedNodeState', () {
    test('initial state has no data', () {
      const state = RecommendedNodeState();
      expect(state.isEmpty, true);
      expect(state.hasData, false);
      expect(state.primary, null);
    });

    test('copyWith updates fields', () {
      const state = RecommendedNodeState();
      final updated = state.copyWith(
        nodes: [
          NodeInfo(
            nodeId: 'n1',
            nodeName: 'Best',
            status: 'online',
            loadScore: 0.1,
            cpuUsage: 10,
            memoryUsage: 20,
            activeConnections: 30,
            degraded: false,
          ),
        ],
      );
      expect(updated.hasData, true);
      expect(updated.isEmpty, false);
      expect(updated.primary?.nodeName, 'Best');
    });
  });
}
