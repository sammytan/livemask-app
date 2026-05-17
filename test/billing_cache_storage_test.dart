import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/models/billing_models.dart';
import 'package:livemask_app/storage/billing_cache_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BillingCacheStorage', () {
    late BillingCacheStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('save and read plans', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = BillingCacheStorage(prefs: prefs);

      final plans = [
        BillingPlan(
          planId: 'free', name: 'Free', priceCents: 0, currency: 'USD',
          billingPeriod: 'monthly', deviceLimit: 1, nodeAccess: 'basic',
          features: [],
        ),
      ];

      await storage.savePlans(BillingPlansResponse(plans: plans));
      final cached = storage.readPlans();
      expect(cached, isNotNull);
      expect(cached!.plans.length, 1);
      expect(cached.plans.first.planId, 'free');
    });

    test('save and read subscription', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = BillingCacheStorage(prefs: prefs);

      final sub = SubscriptionInfo(
        planId: 'premium_monthly', status: 'active', deviceLimit: 5, deviceUsed: 2,
      );

      await storage.saveSubscription(SubscriptionResponse(subscription: sub));
      final cached = storage.readSubscription();
      expect(cached, isNotNull);
      expect(cached!.subscription!.planId, 'premium_monthly');
    });

    test('save and read history', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = BillingCacheStorage(prefs: prefs);

      final items = [
        BillingHistoryItem(
          invoiceId: 'inv-001', planId: 'p', amountCents: 999,
          currency: 'USD', status: 'paid',
        ),
      ];

      await storage.saveHistory(BillingHistoryResponse(items: items));
      final cached = storage.readHistory();
      expect(cached, isNotNull);
      expect(cached!.items.length, 1);
    });

    test('save and read devices', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = BillingCacheStorage(prefs: prefs);

      final devices = [
        DeviceInfo(
          deviceId: 'd1', deviceName: 'Phone', platform: 'ios', trusted: true,
        ),
      ];

      await storage.saveDevices(DevicesResponse(
        devices: devices, deviceLimit: 5, deviceUsed: 1,
      ));
      final cached = storage.readDevices();
      expect(cached, isNotNull);
      expect(cached!.devices.length, 1);
      expect(cached.deviceLimit, 5);
    });

    test('corrupt JSON returns null', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = BillingCacheStorage(prefs: prefs);

      await prefs.setString('billing_cache_plans', 'not valid json');
      final cached = storage.readPlans();
      expect(cached, isNull);
    });

    test('clearCache removes all keys', () async {
      final prefs = await SharedPreferences.getInstance();
      storage = BillingCacheStorage(prefs: prefs);

      final plan = BillingPlan(
        planId: 'free', name: 'Free', priceCents: 0, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 1, nodeAccess: 'basic', features: [],
      );
      await storage.savePlans(BillingPlansResponse(plans: [plan]));
      await storage.clearCache();

      expect(storage.readPlans(), isNull);
    });
  });
}
