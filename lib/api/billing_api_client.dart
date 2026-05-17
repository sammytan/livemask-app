import '../models/billing_models.dart';

/// Abstract interface for Billing and Device API operations.
///
/// Allows transparent switching between [RealBillingApiClient] and
/// [MockBillingApiClient].
abstract class BillingApiClient {
  /// Fetches available subscription plans.
  Future<BillingPlansResponse> fetchPlans();

  /// Fetches the current user's subscription.
  Future<SubscriptionResponse> fetchSubscription();

  /// Fetches billing history.
  Future<BillingHistoryResponse> fetchBillingHistory();

  /// Creates a mock checkout for the given plan.
  Future<CheckoutResponse> createMockCheckout(String planId);

  /// Fetches registered devices.
  Future<DevicesResponse> fetchDevices();

  /// Registers a new device.
  Future<DeviceInfo> addDevice(String deviceName, String platform, String appVersion);

  /// Revokes (deletes) a device.
  Future<void> revokeDevice(String deviceId);
}
