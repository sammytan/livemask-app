import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/real_billing_api_client.dart';
import 'package:livemask_app/models/billing_models.dart';

void main() {
  group('RealBillingApiClient', () {
    late Dio dio;
    late RealBillingApiClient client;
    late _MockAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions());
      adapter = _MockAdapter();
      dio.httpClientAdapter = adapter;
      client = RealBillingApiClient(httpClient: dio);
    });

    group('fetchPlans', () {
      test('returns parsed plans on success', () async {
        adapter.response = {
          'plans': [
            {
              'plan_id': 'free',
              'name': 'Free',
              'price_cents': 0,
              'currency': 'USD',
              'billing_period': 'monthly',
              'device_limit': 1,
              'node_access': 'basic',
              'features': ['1 device'],
            },
          ],
        };
        final response = await client.fetchPlans();
        expect(response.plans.length, 1);
        expect(response.plans.first.planId, 'free');
      });

      test('throws BillingException on 401', () async {
        adapter.statusCode = 401;
        expect(
          () => client.fetchPlans(),
          throwsA(isA<BillingException>().having(
            (e) => e.isUnauthorized,
            'isUnauthorized',
            true,
          )),
        );
      });

      test('throws BillingException on 500', () async {
        adapter.statusCode = 500;
        expect(
          () => client.fetchPlans(),
          throwsA(isA<BillingException>().having(
            (e) => e.isServerError,
            'isServerError',
            true,
          )),
        );
      });
    });

    group('fetchSubscription', () {
      test('returns free entitlement style', () async {
        adapter.response = {'subscription': null};
        final response = await client.fetchSubscription();
        expect(response.subscription, isNull);
      });
    });

    group('createMockCheckout', () {
      test('returns checkout response', () async {
        adapter.response = {
          'checkout_id': 'ch-001',
          'status': 'mock_created',
        };
        final response = await client.createMockCheckout('premium_monthly');
        expect(response.isMockCreated, true);
        expect(response.checkoutId, 'ch-001');
      });
    });

    group('fetchDevices', () {
      test('returns devices response', () async {
        adapter.response = {
          'devices': [
            {
              'device_id': 'd1',
              'device_name': 'Phone',
              'platform': 'ios',
              'trusted': true,
            },
          ],
          'device_limit': 5,
          'device_used': 1,
        };
        final response = await client.fetchDevices();
        expect(response.devices.length, 1);
        expect(response.deviceLimit, 5);
      });
    });

    group('addDevice', () {
      test('returns device on success', () async {
        adapter.response = {
          'device_id': 'd2',
          'device_name': 'New Phone',
          'platform': 'android',
          'trusted': true,
        };
        final device = await client.addDevice('New Phone', 'android', '0.1.0');
        expect(device.deviceId, 'd2');
        expect(device.deviceName, 'New Phone');
      });

      test('throws BillingException on 409 DEVICE_LIMIT_EXCEEDED', () async {
        adapter.statusCode = 409;
        adapter.response = {
          'error': {
            'code': 'DEVICE_LIMIT_EXCEEDED',
            'message': 'Device limit reached',
          },
        };
        expect(
          () => client.addDevice('X', 'ios', '0.1.0'),
          throwsA(isA<BillingException>().having(
            (e) => e.isDeviceLimitExceeded,
            'isDeviceLimitExceeded',
            true,
          )),
        );
      });
    });

    group('revokeDevice', () {
      test('succeeds on 200', () async {
        adapter.response = {'ok': true};
        await client.revokeDevice('d1');
        // no exception = success
      });
    });
  });

  group('BillingException', () {
    test('properties are accessible', () {
      final exc = BillingException(
        statusCode: 409,
        errorCode: 'DEVICE_LIMIT_EXCEEDED',
        message: 'Device limit reached',
      );
      expect(exc.isDeviceLimitExceeded, true);
      expect(exc.isUnauthorized, false);
      expect(exc.isServerError, false);
    });
  });
}

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
