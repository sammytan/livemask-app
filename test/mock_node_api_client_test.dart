import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/mock_node_api_client.dart';
import 'package:livemask_app/api/node_api_client.dart';
import 'package:livemask_app/models/node_models.dart';

void main() {
  late NodeApiClient client;

  setUp(() {
    client = MockNodeApiClient();
  });

  group('MockNodeApiClient', () {
    test('fetchNodes returns node list', () async {
      final response = await client.fetchNodes();

      expect(response.nodes, isNotEmpty);
      expect(response.total, greaterThan(0));
    });

    test('fetchNodes contains mixed node states', () async {
      final response = await client.fetchNodes();

      expect(response.healthyNodes, isNotEmpty);
      expect(response.degradedNodes, isNotEmpty);
      expect(
        response.nodes.where((n) => n.isOffline),
        isNotEmpty,
      );
    });

    test('fetchNodes degraded node is marked not recommended', () async {
      final response = await client.fetchNodes();
      final degraded = response.degradedNodes;

      for (final node in degraded) {
        expect(node.isDegraded, true);
        expect(node.isOnline, false);
      }
    });

    test('fetchRecommended returns healthy nodes sorted by load', () async {
      final response = await client.fetchRecommended();

      expect(response.isEmpty, false);
      // All recommended nodes should be non-degraded and online.
      for (final node in response.nodes) {
        expect(node.degraded, false);
        expect(node.isOnline, true);
      }

      // Verify sort by load score ascending.
      for (int i = 0; i < response.nodes.length - 1; i++) {
        expect(
          response.nodes[i].loadScore <= response.nodes[i + 1].loadScore,
          true,
        );
      }
    });

    test('fetchRecommended excludes degraded nodes', () async {
      final response = await client.fetchRecommended();
      final degraded = response.nodes.where((n) => n.degraded);

      expect(degraded, isEmpty);
    });

    test('fetchRecommended excludes offline nodes', () async {
      final response = await client.fetchRecommended();
      final offline = response.nodes.where((n) => n.isOffline);

      expect(offline, isEmpty);
    });
  });
}
