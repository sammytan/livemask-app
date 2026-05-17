import 'package:dio/dio.dart';
import '../models/billing_models.dart';
import 'billing_api_client.dart';

/// Real API client for billing/device endpoints using Dio.
///
/// Communicates with the Backend's `/api/v1/billing/*` and
/// `/api/v1/devices/*` endpoints.
class RealBillingApiClient implements BillingApiClient {
  RealBillingApiClient({
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
  Future<BillingPlansResponse> fetchPlans() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        _url('api/v1/billing/plans'),
      );
      return BillingPlansResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toBillingException(e);
    }
  }

  @override
  Future<SubscriptionResponse> fetchSubscription() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        _url('api/v1/billing/subscription'),
      );
      return SubscriptionResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toBillingException(e);
    }
  }

  @override
  Future<BillingHistoryResponse> fetchBillingHistory() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        _url('api/v1/billing/history'),
      );
      return BillingHistoryResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toBillingException(e);
    }
  }

  @override
  Future<CheckoutResponse> createMockCheckout(String planId) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        _url('api/v1/billing/checkout'),
        data: CheckoutRequest(planId: planId, paymentMethod: 'mock').toJson(),
      );
      return CheckoutResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toBillingException(e);
    }
  }

  @override
  Future<DevicesResponse> fetchDevices() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        _url('api/v1/devices'),
      );
      return DevicesResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toBillingException(e);
    }
  }

  @override
  Future<DeviceInfo> addDevice(
      String deviceName, String platform, String appVersion) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        _url('api/v1/devices'),
        data: {
          'device_name': deviceName,
          'platform': platform,
          'app_version': appVersion,
        },
      );
      return DeviceInfo.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toBillingException(e);
    }
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    try {
      await _httpClient.delete<Map<String, dynamic>>(
        _url('api/v1/devices/$deviceId'),
      );
    } on DioException catch (e) {
      throw _toBillingException(e);
    }
  }

  BillingException _toBillingException(DioException e) {
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

    return BillingException(
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
        final sc = e.response?.statusCode;
        if (sc == 401) return 'AUTH_TOKEN_EXPIRED';
        if (sc == 409) return 'DEVICE_LIMIT_EXCEEDED';
        return 'HTTP_${sc ?? 0}';
      case DioExceptionType.cancel:
        return 'REQUEST_CANCELLED';
      default:
        return 'BILLING_REQUEST_FAILED';
    }
  }

  String _fallbackMessage(DioException e, int statusCode) {
    if (statusCode == 401) return 'Session expired. Please log in again.';
    if (statusCode == 409) return 'Device limit reached. Please remove a device first.';
    if (statusCode >= 500) return 'Backend is temporarily unavailable.';
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to Backend.';
    }
    return 'Failed to fetch billing data.';
  }
}

/// Structured exception for billing/device API errors.
class BillingException implements Exception {
  const BillingException({
    required this.statusCode,
    required this.errorCode,
    required this.message,
  });

  final int statusCode;
  final String errorCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isServerError => statusCode >= 500;
  bool get isDeviceLimitExceeded =>
      statusCode == 409 || errorCode == 'DEVICE_LIMIT_EXCEEDED';

  @override
  String toString() => 'BillingException($statusCode, $errorCode): $message';
}
