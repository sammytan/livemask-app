import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/billing_api_client.dart';
import 'package:livemask_app/api/mock_billing_api_client.dart';
import 'package:livemask_app/api/real_billing_api_client.dart';
import 'package:livemask_app/models/billing_models.dart';

void main() {
  late BillingApiClient client;

  setUp(() {
    client = MockBillingApiClient();
  });

  group('MockBillingApiClient', () {
    test('fetchPlans returns 3 plans', () async {
      final response = await client.fetchPlans();
      expect(response.plans.length, 3);
      expect(response.plans[0].planId, 'free');
      expect(response.plans[1].planId, 'premium_monthly');
      expect(response.plans[2].planId, 'enterprise_monthly');
    });

    test('fetchSubscription returns null when not subscribed', () async {
      final response = await client.fetchSubscription();
      expect(response.subscription, isNull);
    });

    test('createMockCheckout creates subscription', () async {
      final checkout = await client.createMockCheckout('premium_monthly');
      expect(checkout.isMockCreated, true);

      final sub = await client.fetchSubscription();
      expect(sub.subscription, isNotNull);
      expect(sub.subscription!.planId, 'premium_monthly');
      expect(sub.subscription!.deviceLimit, 5);
    });

    test('billing history is empty for free users', () async {
      final history = await client.fetchBillingHistory();
      expect(history.isEmpty, true);
    });

    test('billing history exists after checkout', () async {
      await client.createMockCheckout('premium_monthly');
      final history = await client.fetchBillingHistory();
      expect(history.isEmpty, false);
      expect(history.items.first.planId, 'premium_monthly');
    });

    test('fetchDevices returns empty list initially', () async {
      final response = await client.fetchDevices();
      expect(response.isEmpty, true);
      expect(response.deviceLimit, 1); // default free
    });

    test('addDevice succeeds', () async {
      // First checkout to get non-free device limit
      await client.createMockCheckout('premium_monthly');

      final device = await client.addDevice('Test Phone', 'ios', '0.1.0');
      expect(device.deviceName, 'Test Phone');
      expect(device.platform, 'ios');

      // Verify device list
      final devices = await client.fetchDevices();
      expect(devices.devices.length, 1);
      expect(devices.deviceUsed, 1);

      // Verify subscription device_used updated
      final sub = await client.fetchSubscription();
      expect(sub.subscription!.deviceUsed, 1);
    });

    test('addDevice returns 409 when at limit', () async {
      await client.createMockCheckout('free'); // device_limit=1
      await client.addDevice('Device 1', 'ios', '0.1.0');

      expect(
        () => client.addDevice('Device 2', 'android', '0.1.0'),
        throwsA(isA<BillingException>().having(
          (e) => e.isDeviceLimitExceeded,
          'isDeviceLimitExceeded',
          true,
        )),
      );
    });

    test('revokeDevice removes device and updates counts', () async {
      await client.createMockCheckout('premium_monthly');
      await client.addDevice('Device 1', 'ios', '0.1.0');
      await client.addDevice('Device 2', 'android', '0.1.0');

      var devices = await client.fetchDevices();
      expect(devices.devices.length, 2);

      await client.revokeDevice(devices.devices.first.deviceId);

      devices = await client.fetchDevices();
      expect(devices.devices.length, 1);
    });
  });
}
