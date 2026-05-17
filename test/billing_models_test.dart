import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/models/billing_models.dart';

void main() {
  group('BillingPlan', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'plan_id': 'premium_monthly',
        'name': 'Premium',
        'price_cents': 999,
        'currency': 'USD',
        'billing_period': 'monthly',
        'device_limit': 5,
        'node_access': 'all',
        'features': ['5 devices', 'All nodes'],
      };
      final plan = BillingPlan.fromJson(json);

      expect(plan.planId, 'premium_monthly');
      expect(plan.name, 'Premium');
      expect(plan.priceCents, 999);
      expect(plan.currency, 'USD');
      expect(plan.billingPeriod, 'monthly');
      expect(plan.deviceLimit, 5);
      expect(plan.nodeAccess, 'all');
      expect(plan.features, ['5 devices', 'All nodes']);
    });

    test('priceFormatted formats cents to dollars', () {
      expect(BillingPlan(
        planId: 'a', name: 'A', priceCents: 0, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 1, nodeAccess: 'basic', features: [],
      ).priceFormatted, '\$0.00');

      expect(BillingPlan(
        planId: 'b', name: 'B', priceCents: 999, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 5, nodeAccess: 'all', features: [],
      ).priceFormatted, '\$9.99');

      expect(BillingPlan(
        planId: 'c', name: 'C', priceCents: 2999, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 25, nodeAccess: 'all', features: [],
      ).priceFormatted, '\$29.99');
    });

    test('priceDescription returns correct text', () {
      final free = BillingPlan(
        planId: 'free', name: 'Free', priceCents: 0, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 1, nodeAccess: 'basic', features: [],
      );
      expect(free.priceDescription, 'Free');

      final paid = BillingPlan(
        planId: 'p', name: 'P', priceCents: 999, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 5, nodeAccess: 'all', features: [],
      );
      expect(paid.priceDescription, '\$9.99/mo');
    });

    test('isFree returns true for zero price', () {
      expect(BillingPlan(
        planId: 'f', name: 'Free', priceCents: 0, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 1, nodeAccess: 'basic', features: [],
      ).isFree, true);
      expect(BillingPlan(
        planId: 'p', name: 'P', priceCents: 999, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 5, nodeAccess: 'all', features: [],
      ).isFree, false);
    });

    test('fromJson handles null features', () {
      final json = {
        'plan_id': 'free',
        'name': 'Free',
        'price_cents': 0,
        'currency': 'USD',
        'billing_period': 'monthly',
        'device_limit': 1,
        'node_access': 'basic',
      };
      final plan = BillingPlan.fromJson(json);
      expect(plan.features, isEmpty);
    });

    test('fromJson handles missing fields with defaults', () {
      final plan = BillingPlan.fromJson({});
      expect(plan.planId, '');
      expect(plan.priceCents, 0);
      expect(plan.currency, 'USD');
      expect(plan.billingPeriod, 'monthly');
    });

    test('toJson produces correct output', () {
      final plan = BillingPlan(
        planId: 'free', name: 'Free', priceCents: 0, currency: 'USD',
        billingPeriod: 'monthly', deviceLimit: 1, nodeAccess: 'basic',
        features: ['1 device'],
      );
      final json = plan.toJson();
      expect(json['plan_id'], 'free');
      expect(json['price_cents'], 0);
      expect(json['features'], ['1 device']);
    });
  });

  group('SubscriptionInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'subscription_id': 'sub-001',
        'plan_id': 'premium_monthly',
        'status': 'active',
        'current_period_start': '2026-05-01T00:00:00Z',
        'current_period_end': '2026-06-01T00:00:00Z',
        'renew_at': '2026-06-01T00:00:00Z',
        'cancel_at_period_end': false,
        'device_limit': 5,
        'device_used': 2,
      };
      final sub = SubscriptionInfo.fromJson(json);
      expect(sub.subscriptionId, 'sub-001');
      expect(sub.planId, 'premium_monthly');
      expect(sub.status, 'active');
      expect(sub.currentPeriodEnd, '2026-06-01T00:00:00Z');
      expect(sub.deviceLimit, 5);
      expect(sub.deviceUsed, 2);
      expect(sub.isActive, true);
      expect(sub.isFree, false);
    });

    test('free entitlement when no subscription', () {
      const sub = SubscriptionInfo(planId: 'free', status: 'active');
      expect(sub.isFree, true);
      expect(sub.isActive, true);
    });

    test('status helpers', () {
      final active = SubscriptionInfo(planId: 'p', status: 'active');
      expect(active.isActive, true);
      expect(active.isExpiring, false);

      final expiring = SubscriptionInfo(planId: 'p', status: 'expiring');
      expect(expiring.isExpiring, true);

      final suspended = SubscriptionInfo(planId: 'p', status: 'suspended');
      expect(suspended.isSuspended, true);
    });

    test('hasDeviceCapacity', () {
      expect(SubscriptionInfo(planId: 'p', status: 'active', deviceLimit: 5, deviceUsed: 2).hasDeviceCapacity, true);
      expect(SubscriptionInfo(planId: 'p', status: 'active', deviceLimit: 2, deviceUsed: 2).hasDeviceCapacity, false);
    });
  });

  group('BillingHistoryItem', () {
    test('fromJson parses all fields', () {
      final json = {
        'invoice_id': 'inv-001',
        'plan_id': 'premium_monthly',
        'amount_cents': 999,
        'currency': 'USD',
        'status': 'paid',
        'paid_at': '2026-05-10T00:00:00Z',
        'created_at': '2026-05-10T00:00:00Z',
      };
      final item = BillingHistoryItem.fromJson(json);
      expect(item.invoiceId, 'inv-001');
      expect(item.planId, 'premium_monthly');
      expect(item.amountCents, 999);
      expect(item.amountFormatted, '\$9.99');
      expect(item.isPaid, true);
    });

    test('status helpers', () {
      expect(BillingHistoryItem(invoiceId: 'a', planId: 'p', amountCents: 0, currency: 'USD', status: 'paid').isPaid, true);
      expect(BillingHistoryItem(invoiceId: 'a', planId: 'p', amountCents: 0, currency: 'USD', status: 'pending').isPending, true);
      expect(BillingHistoryItem(invoiceId: 'a', planId: 'p', amountCents: 0, currency: 'USD', status: 'failed').isFailed, true);
    });
  });

  group('DeviceInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'device_id': 'dev-001',
        'device_name': 'Sammy iPhone',
        'platform': 'ios',
        'app_version': '0.1.0',
        'trusted': true,
        'last_active_at': '2026-05-17T10:00:00Z',
        'created_at': '2026-05-01T00:00:00Z',
      };
      final device = DeviceInfo.fromJson(json);
      expect(device.deviceId, 'dev-001');
      expect(device.deviceName, 'Sammy iPhone');
      expect(device.platform, 'ios');
      expect(device.appVersion, '0.1.0');
      expect(device.trusted, true);
    });

    test('platform helpers', () {
      expect(DeviceInfo(deviceId: 'a', deviceName: 'A', platform: 'ios').platformLabel, 'iOS');
      expect(DeviceInfo(deviceId: 'a', deviceName: 'A', platform: 'android').platformLabel, 'Android');
      expect(DeviceInfo(deviceId: 'a', deviceName: 'A', platform: 'macos').platformLabel, 'macOS');
    });
  });

  group('Response wrappers', () {
    test('BillingPlansResponse handles null plans', () {
      final response = BillingPlansResponse.fromJson({});
      expect(response.isEmpty, true);
      expect(response.plans, isEmpty);
    });

    test('BillingPlansResponse handles empty plans', () {
      final response = BillingPlansResponse.fromJson({'plans': []});
      expect(response.isEmpty, true);
    });

    test('SubscriptionResponse returns free entitlement for null sub', () {
      final response = SubscriptionResponse.fromJson({});
      expect(response.subscription, isNull);
      expect(response.effectiveSubscription.isFree, true);
      expect(response.effectiveSubscription.deviceLimit, 1);
    });

    test('SubscriptionResponse parses subscription', () {
      final response = SubscriptionResponse.fromJson({
        'subscription': {
          'plan_id': 'premium_monthly',
          'status': 'active',
          'device_limit': 5,
          'device_used': 2,
        },
      });
      expect(response.subscription, isNotNull);
      expect(response.subscription!.planId, 'premium_monthly');
    });

    test('BillingHistoryResponse handles null items', () {
      final response = BillingHistoryResponse.fromJson({});
      expect(response.isEmpty, true);
    });

    test('DevicesResponse parses list and limits', () {
      final response = DevicesResponse.fromJson({
        'devices': [{'device_id': 'd1', 'device_name': 'D1', 'platform': 'ios'}],
        'device_limit': 5,
        'device_used': 1,
      });
      expect(response.devices.length, 1);
      expect(response.deviceLimit, 5);
      expect(response.deviceUsed, 1);
      expect(response.hasCapacity, true);
    });

    test('DevicesResponse has no capacity when at limit', () {
      final response = DevicesResponse.fromJson({
        'devices': [{'device_id': 'd1', 'device_name': 'D1', 'platform': 'ios'}],
        'device_limit': 1,
        'device_used': 1,
      });
      expect(response.hasCapacity, false);
    });
  });

  group('Checkout', () {
    test('CheckoutRequest toJson', () {
      final req = CheckoutRequest(planId: 'premium_monthly', paymentMethod: 'mock');
      final json = req.toJson();
      expect(json['plan_id'], 'premium_monthly');
      expect(json['payment_method'], 'mock');
    });

    test('CheckoutResponse fromJson', () {
      final response = CheckoutResponse.fromJson({
        'checkout_id': 'ch-001',
        'status': 'mock_created',
      });
      expect(response.checkoutId, 'ch-001');
      expect(response.isMockCreated, true);
    });
  });

  group('State containers', () {
    test('BillingPlansState defaults', () {
      const state = BillingPlansState();
      expect(state.hasData, false);
      expect(state.hasError, false);
    });

    test('SubscriptionState effective subscription', () {
      const state = SubscriptionState();
      expect(state.isFree, true);
      expect(state.effective.deviceLimit, 1);
    });

    test('BillingHistoryState empty defaults', () {
      const state = BillingHistoryState();
      expect(state.hasData, false);
    });

    test('DevicesState defaults', () {
      const state = DevicesState();
      expect(state.hasData, false);
      expect(state.hasCapacity, false);
    });
  });
}
