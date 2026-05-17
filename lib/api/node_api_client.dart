import '../models/node_models.dart';

/// Abstract interface for Node API operations.
///
/// Allows transparent switching between [RealNodeApiClient] and
/// [MockNodeApiClient] depending on Backend readiness.
abstract class NodeApiClient {
  /// Fetches the full node list from `GET /api/v1/nodes`.
  Future<NodeListResponse> fetchNodes();

  /// Fetches the recommended node(s) from `GET /api/v1/nodes/recommended`.
  Future<RecommendedNodeResponse> fetchRecommended();
}
