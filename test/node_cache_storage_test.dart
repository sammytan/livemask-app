import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livemask_app/models/node_models.dart';
import 'package:livemask_app/storage/node_cache_storage.dart';

void main() {
  group('NodeCacheStorage', () {
    late NodeCacheStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('readNodeList returns null when no cache', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = NodeCacheStorage(prefs: prefs);

      final result = storage.readNodeList();
      expect(result, isNull);
    });

    test('save and read node list round-trip', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = NodeCacheStorage(prefs: prefs);

      final nodes = [
        NodeInfo(
          nodeId: 'n1',
          nodeName: 'Test Node',
          status: 'online',
          loadScore: 0.5,
          cpuUsage: 50,
          memoryUsage: 60,
          activeConnections: 100,
          degraded: false,
        ),
      ];
      final response = NodeListResponse(nodes: nodes, total: 1);

      await storage.saveNodeList(response);
      final cached = storage.readNodeList();

      expect(cached, isNotNull);
      expect(cached!.nodes.length, 1);
      expect(cached.nodes.first.nodeId, 'n1');
      expect(cached.nodes.first.nodeName, 'Test Node');
    });

    test('readNodeListTimestamp returns null initially', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = NodeCacheStorage(prefs: prefs);

      expect(storage.readNodeListTimestamp(), isNull);
    });

    test('readNodeListTimestamp returns time after save', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = NodeCacheStorage(prefs: prefs);

      await storage.saveNodeList(NodeListResponse(nodes: const []));
      expect(storage.readNodeListTimestamp(), isNotNull);
    });

    test('save and read recommended node round-trip', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = NodeCacheStorage(prefs: prefs);

      final response = RecommendedNodeResponse(
        nodes: [
          NodeInfo(
            nodeId: 'r1',
            nodeName: 'Recommended',
            status: 'online',
            loadScore: 0.2,
            cpuUsage: 20,
            memoryUsage: 30,
            activeConnections: 50,
            degraded: false,
          ),
        ],
      );

      await storage.saveRecommended(response);
      final cached = storage.readRecommended();

      expect(cached, isNotNull);
      expect(cached!.nodes.length, 1);
      expect(cached.nodes.first.nodeId, 'r1');
    });

    test('clearCache removes all data', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = NodeCacheStorage(prefs: prefs);

      await storage.saveNodeList(NodeListResponse(nodes: const []));
      await storage.saveRecommended(RecommendedNodeResponse(nodes: const []));
      expect(storage.readNodeList(), isNotNull);
      expect(storage.readRecommended(), isNotNull);

      await storage.clearCache();
      expect(storage.readNodeList(), isNull);
      expect(storage.readRecommended(), isNull);
    });

    test('readNodeList handles corrupt data gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('node_cache_list', '{invalid json');
      storage = NodeCacheStorage(prefs: prefs);

      expect(storage.readNodeList(), isNull);
    });

    test('readRecommended handles corrupt data gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('node_cache_recommended', 'not json');
      storage = NodeCacheStorage(prefs: prefs);

      expect(storage.readRecommended(), isNull);
    });
  });
}
