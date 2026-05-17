import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/mock_node_api_client.dart';
import '../api/node_api_client.dart';
import '../api/real_node_api_client.dart';
import '../config/app_config.dart';
import '../models/node_models.dart';
import '../services/dio_factory.dart';
import '../storage/node_cache_storage.dart';
import 'auth_providers.dart';
import 'config_providers.dart';

// ============================================================
// Low-level dependency providers
// ============================================================

/// Dio for node API calls.
///
/// Uses [authenticatedDioProvider] for real backend (carries JWT token).
/// Falls back to plain Dio for mock mode.
final nodeDioProvider = Provider<Dio>((ref) {
  if (AppConfig.useMockAuthClient) {
    return DioFactory.createPlainDio();
  }
  return ref.watch(authenticatedDioProvider);
});

/// Node API client provider.
final nodeApiClientProvider = Provider<NodeApiClient>((ref) {
  if (AppConfig.useMockAuthClient) {
    return MockNodeApiClient();
  }
  return RealNodeApiClient(
    httpClient: ref.watch(nodeDioProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
});

/// Node cache storage provider.
final nodeCacheStorageProvider = FutureProvider<NodeCacheStorage>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return NodeCacheStorage(prefs: prefs);
});

// ============================================================
// Node list state management
// ============================================================

/// Provider for the full node list state.
final nodeListStateProvider =
    StateNotifierProvider<NodeListNotifier, NodeListState>((ref) {
  return NodeListNotifier(ref);
});

class NodeListNotifier extends StateNotifier<NodeListState> {
  NodeListNotifier(this._ref) : super(const NodeListState());

  final Ref _ref;

  NodeApiClient get _apiClient => _ref.read(nodeApiClientProvider);

  /// Loads cached node list on startup (lightweight, no network).
  Future<void> loadCached() async {
    final storage = await _ref.read(nodeCacheStorageProvider.future);
    final cached = storage.readNodeList();
    final timestamp = storage.readNodeListTimestamp();
    if (cached != null) {
      state = NodeListState(
        nodes: cached.nodes,
        lastUpdatedAt: timestamp,
        isFromCache: true,
      );
    }
  }

  /// Fetches fresh node list from Backend.
  ///
  /// On success, caches the result.
  /// On failure, falls back to cached data if available.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.fetchNodes();
      final storage = await _ref.read(nodeCacheStorageProvider.future);
      await storage.saveNodeList(response);

      state = NodeListState(
        nodes: response.nodes,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      final errorMsg = e.toString();
      // Try cached fallback.
      final storage = await _ref.read(nodeCacheStorageProvider.future);
      final cached = storage.readNodeList();
      if (cached != null) {
        state = NodeListState(
          nodes: cached.nodes,
          errorMessage: errorMsg,
          lastUpdatedAt: storage.readNodeListTimestamp(),
          isFromCache: true,
        );
      } else {
        state = NodeListState(
          nodes: const [],
          errorMessage: errorMsg,
        );
      }
    }
  }
}

// ============================================================
// Recommended node state management
// ============================================================

/// Provider for the recommended node state.
final recommendedNodeStateProvider =
    StateNotifierProvider<RecommendedNodeNotifier, RecommendedNodeState>(
        (ref) {
  return RecommendedNodeNotifier(ref);
});

class RecommendedNodeNotifier extends StateNotifier<RecommendedNodeState> {
  RecommendedNodeNotifier(this._ref) : super(const RecommendedNodeState());

  final Ref _ref;

  NodeApiClient get _apiClient => _ref.read(nodeApiClientProvider);

  /// Loads cached recommended nodes on startup.
  Future<void> loadCached() async {
    final storage = await _ref.read(nodeCacheStorageProvider.future);
    final cached = storage.readRecommended();
    final timestamp = storage.readRecommendedTimestamp();
    if (cached != null) {
      state = RecommendedNodeState(
        nodes: cached.nodes,
        lastUpdatedAt: timestamp,
        isFromCache: true,
      );
    }
  }

  /// Fetches recommended nodes from Backend.
  ///
  /// On success, caches the result.
  /// On failure, falls back to cached data if available.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.fetchRecommended();
      final storage = await _ref.read(nodeCacheStorageProvider.future);
      await storage.saveRecommended(response);

      state = RecommendedNodeState(
        nodes: response.nodes,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      final errorMsg = e.toString();
      final storage = await _ref.read(nodeCacheStorageProvider.future);
      final cached = storage.readRecommended();
      if (cached != null) {
        state = RecommendedNodeState(
          nodes: cached.nodes,
          errorMessage: errorMsg,
          lastUpdatedAt: storage.readRecommendedTimestamp(),
          isFromCache: true,
        );
      } else {
        state = RecommendedNodeState(nodes: const [], errorMessage: errorMsg);
      }
    }
  }
}
