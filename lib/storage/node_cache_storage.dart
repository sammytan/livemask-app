import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/node_models.dart';

/// Persistent cache for node data using SharedPreferences.
///
/// Provides offline fallback when the Backend is unreachable.
/// Node cache is purely a read/write store — validation is the
/// caller's responsibility.
class NodeCacheStorage {
  NodeCacheStorage({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _nodesCacheKey = 'node_cache_list';
  static const String _nodesTimestampKey = 'node_cache_list_timestamp';
  static const String _recommendedCacheKey = 'node_cache_recommended';
  static const String _recommendedTimestampKey =
      'node_cache_recommended_timestamp';

  // ---- Node list cache ----

  /// Persists the node list to local storage.
  Future<void> saveNodeList(NodeListResponse response) async {
    final nodesJson = jsonEncode(
      response.nodes.map((n) => n.toJson()).toList(),
    );
    await _prefs.setString(_nodesCacheKey, nodesJson);
    await _prefs.setInt(
      _nodesTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Reads the cached node list. Returns null if empty or corrupt.
  NodeListResponse? readNodeList() {
    final jsonStr = _prefs.getString(_nodesCacheKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return NodeListResponse(
        nodes: decoded
            .map((e) => NodeInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: decoded.length,
      );
    } catch (_) {
      return null;
    }
  }

  /// Timestamp of the last successful node list cache write, or null.
  DateTime? readNodeListTimestamp() {
    final ms = _prefs.getInt(_nodesTimestampKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // ---- Recommended node cache ----

  /// Persists the recommended node response to local storage.
  Future<void> saveRecommended(RecommendedNodeResponse response) async {
    final jsonStr = jsonEncode(
      response.nodes.map((n) => n.toJson()).toList(),
    );
    await _prefs.setString(_recommendedCacheKey, jsonStr);
    await _prefs.setInt(
      _recommendedTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Reads the cached recommended nodes. Returns null if empty or corrupt.
  RecommendedNodeResponse? readRecommended() {
    final jsonStr = _prefs.getString(_recommendedCacheKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return RecommendedNodeResponse(
        nodes: decoded
            .map((e) => NodeInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Timestamp of the last successful recommended cache write, or null.
  DateTime? readRecommendedTimestamp() {
    final ms = _prefs.getInt(_recommendedTimestampKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // ---- Bulk operations ----

  /// Clears all cached node data.
  Future<void> clearCache() async {
    await _prefs.remove(_nodesCacheKey);
    await _prefs.remove(_nodesTimestampKey);
    await _prefs.remove(_recommendedCacheKey);
    await _prefs.remove(_recommendedTimestampKey);
  }
}
