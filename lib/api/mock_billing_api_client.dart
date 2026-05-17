import '../models/billing_models.dart';
import 'billing_api_client.dart';
import 'real_billing_api_client.dart';

/// Mock [BillingApiClient] used when the Backend is not ready.
///
/// Returns realistic simulated billing/device data for development and testing.
class MockBillingApiClient implements BillingApiClient {
  MockBillingApiClient();

  static const _mockPlans = [
    BillingPlan(
      planId: 'free',
      name: 'Free',
      priceCents: 0,
      currency: 'USD',
      billingPeriod: 'monthly',
      deviceLimit: 1,
      nodeAccess: 'basic',
      features: ['1 device', 'Basic nodes', 'Community support'],
    ),
    BillingPlan(
      planId: 'premium_monthly',
      name: 'Premium',
      priceCents: 999,
      currency: 'USD',
      billingPeriod: 'monthly',
      deviceLimit: 5,
      nodeAccess: 'all',
      features: [
        'Up to 5 devices',
        'All global nodes',
        'Priority support',
        'No logs',
      ],
    ),
    BillingPlan(
      planId: 'enterprise_monthly',
      name: 'Enterprise',
      priceCents: 2999,
      currency: 'USD',
      billingPeriod: 'monthly',
      deviceLimit: 25,
      nodeAccess: 'all',
      features: [
        'Up to 25 devices',
        'All global nodes',
        'Dedicated support',
        'No logs',
        'Custom protocol',
      ],
    ),
  ];

  SubscriptionInfo? _currentSubscription;

  final List<DeviceInfo> _devices = [];

  @override
  Future<BillingPlansResponse> fetchPlans() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return BillingPlansResponse(plans: _mockPlans);
  }

  @override
  Future<SubscriptionResponse> fetchSubscription() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return SubscriptionResponse(subscription: _currentSubscription);
  }

  @override
  Future<BillingHistoryResponse> fetchBillingHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentSubscription == null || _currentSubscription!.isFree) {
      return const BillingHistoryResponse(items: []);
    }
    return BillingHistoryResponse(items: [
      BillingHistoryItem(
        invoiceId: 'inv-001',
        planId: _currentSubscription!.planId,
        amountCents:
            _currentSubscription!.planId == 'premium_monthly' ? 999 : 2999,
        currency: 'USD',
        status: 'paid',
        paidAt: DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
        createdAt: DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
      ),
    ]);
  }

  @override
  Future<CheckoutResponse> createMockCheckout(String planId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final plan = _mockPlans.firstWhere(
      (p) => p.planId == planId,
      orElse: () => _mockPlans.first,
    );

    _currentSubscription = SubscriptionInfo(
      subscriptionId: 'sub-mock-${DateTime.now().millisecondsSinceEpoch}',
      planId: planId,
      status: 'active',
      currentPeriodStart: DateTime.now().toIso8601String(),
      currentPeriodEnd:
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      renewAt:
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      cancelAtPeriodEnd: false,
      deviceLimit: plan.deviceLimit,
      deviceUsed: _devices.length,
    );

    return CheckoutResponse(
      checkoutId: 'ch-mock-${DateTime.now().millisecondsSinceEpoch}',
      status: 'mock_created',
    );
  }

  @override
  Future<DevicesResponse> fetchDevices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DevicesResponse(
      devices: _devices,
      deviceLimit: _currentSubscription?.deviceLimit ?? 1,
      deviceUsed: _devices.length,
    );
  }

  @override
  Future<DeviceInfo> addDevice(
      String deviceName, String platform, String appVersion) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final limit = _currentSubscription?.deviceLimit ?? 1;
    if (_devices.length >= limit) {
      throw BillingException(
        statusCode: 409,
        errorCode: 'DEVICE_LIMIT_EXCEEDED',
        message: 'Device limit ($limit) reached. Please remove a device first.',
      );
    }

    final device = DeviceInfo(
      deviceId: 'dev-mock-${DateTime.now().millisecondsSinceEpoch}',
      deviceName: deviceName,
      platform: platform,
      appVersion: appVersion,
      trusted: true,
      lastActiveAt: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );
    _devices.add(device);

    _updateDeviceCount();
    return device;
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _devices.removeWhere((d) => d.deviceId == deviceId);
    _updateDeviceCount();
  }

  void _updateDeviceCount() {
    if (_currentSubscription != null) {
      _currentSubscription = SubscriptionInfo(
        subscriptionId: _currentSubscription!.subscriptionId,
        planId: _currentSubscription!.planId,
        status: _currentSubscription!.status,
        currentPeriodStart: _currentSubscription!.currentPeriodStart,
        currentPeriodEnd: _currentSubscription!.currentPeriodEnd,
        renewAt: _currentSubscription!.renewAt,
        cancelAtPeriodEnd: _currentSubscription!.cancelAtPeriodEnd,
        deviceLimit: _currentSubscription!.deviceLimit,
        deviceUsed: _devices.length,
      );
    }
  }
}
