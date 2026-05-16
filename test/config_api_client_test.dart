import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/config_api_client.dart';
import 'package:livemask_app/config/platform_info.dart';
import 'package:livemask_app/models/remote_config.dart';

void main() {
  group('ConfigApiClient', () {
    late Dio httpClient;
    late ConfigApiClient apiClient;

    setUp(() {
      httpClient = Dio(BaseOptions());
      apiClient = ConfigApiClient(httpClient: httpClient);
    });

    test('fetchClientConfig builds correct URL and query params', () async {
      httpClient.options.baseUrl = 'https://api.test';
      final adapter = _MockAdapter();
      httpClient.httpClientAdapter = adapter;

      adapter.onGet(
        '/api/v1/config/client',
        response: {
          'schema_version': '1.0',
          'config_key': 'client.remote_config',
          'config_version': 3,
          'config_hash':
              'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          'payload': {
            'connection': {'recommendation_ttl_seconds': 120},
          },
          'published_at': '2026-05-16T12:00:00Z',
        },
      );

      final platformInfo = PlatformInfo(
        clientVersion: '0.1.0',
        platform: 'macos',
      );

      final response = await apiClient.fetchClientConfig(
        platformInfo: platformInfo,
        localConfigVersion: 2,
      );

      expect(response.configKey, 'client.remote_config');
      expect(response.configVersion, 3);
      expect(response.payload['connection']['recommendation_ttl_seconds'], 120);
    });

    test('fetchClientConfig without local version omits config_version param',
        () async {
      httpClient.options.baseUrl = 'https://api.test';
      final adapter = _MockAdapter();
      httpClient.httpClientAdapter = adapter;

      adapter.onGet(
        '/api/v1/config/client',
        response: {
          'schema_version': '1.0',
          'config_key': 'client.remote_config',
          'config_version': 1,
          'config_hash':
              'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          'payload': {},
        },
      );

      final platformInfo = PlatformInfo(
        clientVersion: '0.1.0',
        platform: 'android',
      );

      final response = await apiClient.fetchClientConfig(
        platformInfo: platformInfo,
      );

      expect(response.configVersion, 1);
    });
  });
}

/// A minimal mock that returns a pre-configured JSON response for any GET.
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter();

  Map<String, dynamic>? _response;

  void onGet(String path, {required Map<String, dynamic> response}) {
    _response = response;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_response ?? <String, dynamic>{}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close() {}
}
