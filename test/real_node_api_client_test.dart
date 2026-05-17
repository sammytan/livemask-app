import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/real_node_api_client.dart';
import 'package:livemask_app/models/node_models.dart';

void main() {
  group('RealNodeApiClient', () {
    late Dio dio;
    late RealNodeApiClient client;
    late _MockAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions());
      adapter = _MockAdapter();
      dio.httpClientAdapter = adapter;
      client = RealNodeApiClient(httpClient: dio);
    });

    group('fetchNodes', () {
      test('returns parsed NodeListResponse on success', () async {
        adapter.response = {
          'nodes': [
            {
              'node_id': 'n1',
              'node_name': 'Node 1',
              'status': 'online',
              'load_score': 0.5,
              'cpu_usage': 50.0,
              'memory_usage': 60.0,
              'active_connections': 100,
              'degraded': false,
              'last_heartbeat_at': '2026-05-17T10:00:00Z',
            },
          ],
          'total': 1,
        };

        final response = await client.fetchNodes();
        expect(response.nodes.length, 1);
        expect(response.nodes.first.nodeName, 'Node 1');
        expect(response.nodes.first.isOnline, true);
      });

      test('throws NodeException on 401', () async {
        adapter.statusCode = 401;
        adapter.response = {
          'error': {
            'code': 'AUTH_TOKEN_EXPIRED',
            'message': 'Session expired',
          },
        };

        expect(
          () => client.fetchNodes(),
          throwsA(
            isA<NodeException>().having(
              (e) => e.isUnauthorized,
              'isUnauthorized',
              true,
            ),
          ),
        );
      });

      test('throws NodeException on 500', () async {
        adapter.statusCode = 500;
        adapter.response = {
          'error': {'code': 'INTERNAL_ERROR'},
        };

        expect(
          () => client.fetchNodes(),
          throwsA(
            isA<NodeException>().having(
              (e) => e.isServerError,
              'isServerError',
              true,
            ),
          ),
        );
      });
    });

    group('fetchRecommended', () {
      test('returns parsed RecommendedNodeResponse on success', () async {
        adapter.response = {
          'nodes': [
            {
              'node_id': 'r1',
              'node_name': 'Best Node',
              'status': 'online',
              'load_score': 0.2,
              'cpu_usage': 20.0,
              'memory_usage': 30.0,
              'active_connections': 50,
              'degraded': false,
            },
          ],
        };

        final response = await client.fetchRecommended();
        expect(response.isEmpty, false);
        expect(response.primary?.nodeName, 'Best Node');
      });

      test('throws NodeException on error', () async {
        adapter.statusCode = 403;
        adapter.response = {
          'error': {'code': 'FORBIDDEN'},
        };

        expect(
          () => client.fetchRecommended(),
          throwsA(isA<NodeException>()),
        );
      });
    });
  });

  group('NodeException', () {
    test('properties are accessible', () {
      final exc = NodeException(
        statusCode: 401,
        errorCode: 'AUTH_EXPIRED',
        message: 'Token expired',
      );
      expect(exc.statusCode, 401);
      expect(exc.errorCode, 'AUTH_EXPIRED');
      expect(exc.message, 'Token expired');
      expect(exc.isUnauthorized, true);
      expect(exc.isServerError, false);
    });

    test('toString includes all fields', () {
      final exc = NodeException(
        statusCode: 500,
        errorCode: 'INTERNAL_ERROR',
        message: 'Server error',
      );
      final str = exc.toString();
      expect(str, contains('500'));
      expect(str, contains('INTERNAL_ERROR'));
      expect(str, contains('Server error'));
    });
  });
}

/// A minimal mock that returns a pre-configured JSON response.
class _MockAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Map<String, dynamic>? response;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(response ?? <String, dynamic>{}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
