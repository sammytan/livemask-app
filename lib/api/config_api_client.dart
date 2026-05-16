import 'package:dio/dio.dart';
import '../models/remote_config.dart';
import '../config/platform_info.dart';

/// API client for `GET /api/v1/config/client`.
///
/// Thin wrapper around Dio that handles the request / response shape
/// defined in the config-center API contract.
class ConfigApiClient {
  ConfigApiClient({
    required Dio httpClient,
    this.baseUrl = '',
  }) : _httpClient = httpClient;

  final Dio _httpClient;
  final String baseUrl;

  /// Fetches the latest remote config from the Backend.
  ///
  /// Throws [DioException] on network errors or non-200 responses.
  Future<RemoteConfigResponse> fetchClientConfig({
    required PlatformInfo platformInfo,
    int localConfigVersion = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'client_version': platformInfo.clientVersion,
      'platform': platformInfo.platform,
    };
    if (localConfigVersion > 0) {
      queryParams['config_version'] = localConfigVersion;
    }

    final url = '${baseUrl}/api/v1/config/client';
    final response = await _httpClient.get<Map<String, dynamic>>(
      url,
      queryParameters: queryParams,
    );

    final body = response.data;
    if (body == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response body',
        type: DioExceptionType.badResponse,
        response: response,
      );
    }

    return RemoteConfigResponse.fromJson(body);
  }
}
