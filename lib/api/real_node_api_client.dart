import 'package:dio/dio.dart';
import '../models/node_models.dart';
import 'node_api_client.dart';

/// Real API client for node endpoints using Dio.
///
/// Communicates with the Backend's `/api/v1/nodes` and
/// `/api/v1/nodes/recommended` endpoints.
class RealNodeApiClient implements NodeApiClient {
  RealNodeApiClient({
    required Dio httpClient,
    this.baseUrl = '',
  }) : _httpClient = httpClient;

  final Dio _httpClient;
  final String baseUrl;

  String _url(String path) {
    if (baseUrl.isEmpty) return '/$path';
    return '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/$path';
  }

  @override
  Future<NodeListResponse> fetchNodes() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        _url('api/v1/nodes'),
      );
      return NodeListResponse.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (e) {
      throw _toNodeException(e);
    }
  }

  @override
  Future<RecommendedNodeResponse> fetchRecommended() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        _url('api/v1/nodes/recommended'),
      );
      return RecommendedNodeResponse.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (e) {
      throw _toNodeException(e);
    }
  }

  /// Converts a [DioException] into a [NodeException].
  NodeException _toNodeException(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    String? errorCode;
    String? message;

    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        errorCode = error['code']?.toString();
        message = error['message']?.toString();
      } else {
        errorCode = data['code']?.toString();
        message = data['message']?.toString();
      }
    }

    return NodeException(
      statusCode: statusCode,
      errorCode: errorCode ?? _fallbackCode(e),
      message: message ?? _fallbackMessage(e, statusCode),
    );
  }

  String _fallbackCode(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'NETWORK_TIMEOUT';
      case DioExceptionType.connectionError:
        return 'NETWORK_CONNECTION_ERROR';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) return 'AUTH_TOKEN_EXPIRED';
        return 'HTTP_${e.response?.statusCode ?? 0}';
      case DioExceptionType.cancel:
        return 'REQUEST_CANCELLED';
      default:
        return 'NODE_REQUEST_FAILED';
    }
  }

  String _fallbackMessage(DioException e, int statusCode) {
    if (statusCode == 401) return 'Session expired. Please log in again.';
    if (statusCode >= 500) return 'Backend is temporarily unavailable.';
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to Backend.';
    }
    return 'Failed to fetch node data.';
  }
}

/// Structured exception for node API errors.
class NodeException implements Exception {
  const NodeException({
    required this.statusCode,
    required this.errorCode,
    required this.message,
  });

  final int statusCode;
  final String errorCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => 'NodeException($statusCode, $errorCode): $message';
}
