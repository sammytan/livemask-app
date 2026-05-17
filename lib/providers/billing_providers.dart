import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/billing_api_client.dart';
import '../api/mock_billing_api_client.dart';
import '../api/real_billing_api_client.dart';
import '../config/app_config.dart';
import '../models/billing_models.dart';
import '../services/dio_factory.dart';
import '../storage/billing_cache_storage.dart';
import 'auth_providers.dart';
import 'config_providers.dart';

// ============================================================
// Low-level dependency providers
// ============================================================

/// Dio for billing/device API calls.
final billingDioProvider = Provider<Dio>((ref) {
  if (AppConfig.useMockAuthClient) {
    return DioFactory.createPlainDio();
  }
  return ref.watch(authenticatedDioProvider);
});

/// Billing API client provider.
final billingApiClientProvider = Provider<BillingApiClient>((ref) {
  if (AppConfig.useMockAuthClient) {
    return MockBillingApiClient();
  }
  return RealBillingApiClient(
    httpClient: ref.watch(billingDioProvider),
    baseUrl: AppConfig.apiBaseUrl,
  );
});

/// Billing cache storage provider.
final billingCacheStorageProvider =
    FutureProvider<BillingCacheStorage>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return BillingCacheStorage(prefs: prefs);
});

// ============================================================
// Billing Plans
// ============================================================

final billingPlansStateProvider =
    StateNotifierProvider<BillingPlansNotifier, BillingPlansState>((ref) {
  return BillingPlansNotifier(ref);
});

class BillingPlansNotifier extends StateNotifier<BillingPlansState> {
  BillingPlansNotifier(this._ref) : super(const BillingPlansState());

  final Ref _ref;

  BillingApiClient get _api => _ref.read(billingApiClientProvider);

  Future<void> loadCached() async {
    final storage = await _ref.read(billingCacheStorageProvider.future);
    final cached = storage.readPlans();
    final ts = storage.readPlansTimestamp();
    if (cached != null) {
      state = BillingPlansState(
        plans: cached.plans,
        lastUpdatedAt: ts,
        isFromCache: true,
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.fetchPlans();
      final storage = await _ref.read(billingCacheStorageProvider.future);
      await storage.savePlans(response);
      state = BillingPlansState(
        plans: response.plans,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      final errorMsg = e.toString();
      final storage = await _ref.read(billingCacheStorageProvider.future);
      final cached = storage.readPlans();
      if (cached != null) {
        state = BillingPlansState(
          plans: cached.plans,
          errorMessage: errorMsg,
          lastUpdatedAt: storage.readPlansTimestamp(),
          isFromCache: true,
        );
      } else {
        state = BillingPlansState(plans: const [], errorMessage: errorMsg);
      }
    }
  }
}

// ============================================================
// Subscription
// ============================================================

final subscriptionStateProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref);
});

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this._ref) : super(const SubscriptionState());

  final Ref _ref;

  BillingApiClient get _api => _ref.read(billingApiClientProvider);

  Future<void> loadCached() async {
    final storage = await _ref.read(billingCacheStorageProvider.future);
    final cached = storage.readSubscription();
    final ts = storage.readSubscriptionTimestamp();
    if (cached != null) {
      state = SubscriptionState(
        subscription: cached.subscription,
        lastUpdatedAt: ts,
        isFromCache: true,
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.fetchSubscription();
      final storage = await _ref.read(billingCacheStorageProvider.future);
      await storage.saveSubscription(response);
      state = SubscriptionState(
        subscription: response.subscription,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      final errorMsg = e.toString();
      final storage = await _ref.read(billingCacheStorageProvider.future);
      final cached = storage.readSubscription();
      if (cached != null) {
        state = SubscriptionState(
          subscription: cached.subscription,
          errorMessage: errorMsg,
          lastUpdatedAt: storage.readSubscriptionTimestamp(),
          isFromCache: true,
        );
      } else {
        state = SubscriptionState(subscription: null, errorMessage: errorMsg);
      }
    }
  }
}

// ============================================================
// Billing History
// ============================================================

final billingHistoryStateProvider =
    StateNotifierProvider<BillingHistoryNotifier, BillingHistoryState>((ref) {
  return BillingHistoryNotifier(ref);
});

class BillingHistoryNotifier extends StateNotifier<BillingHistoryState> {
  BillingHistoryNotifier(this._ref) : super(const BillingHistoryState());

  final Ref _ref;

  BillingApiClient get _api => _ref.read(billingApiClientProvider);

  Future<void> loadCached() async {
    final storage = await _ref.read(billingCacheStorageProvider.future);
    final cached = storage.readHistory();
    final ts = storage.readHistoryTimestamp();
    if (cached != null) {
      state = BillingHistoryState(
        items: cached.items,
        lastUpdatedAt: ts,
        isFromCache: true,
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.fetchBillingHistory();
      final storage = await _ref.read(billingCacheStorageProvider.future);
      await storage.saveHistory(response);
      state = BillingHistoryState(
        items: response.items,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      final errorMsg = e.toString();
      final storage = await _ref.read(billingCacheStorageProvider.future);
      final cached = storage.readHistory();
      if (cached != null) {
        state = BillingHistoryState(
          items: cached.items,
          errorMessage: errorMsg,
          lastUpdatedAt: storage.readHistoryTimestamp(),
          isFromCache: true,
        );
      } else {
        state = BillingHistoryState(items: const [], errorMessage: errorMsg);
      }
    }
  }
}

// ============================================================
// Devices
// ============================================================

final devicesStateProvider =
    StateNotifierProvider<DevicesNotifier, DevicesState>((ref) {
  return DevicesNotifier(ref);
});

class DevicesNotifier extends StateNotifier<DevicesState> {
  DevicesNotifier(this._ref) : super(const DevicesState());

  final Ref _ref;

  BillingApiClient get _api => _ref.read(billingApiClientProvider);

  Future<void> loadCached() async {
    final storage = await _ref.read(billingCacheStorageProvider.future);
    final cached = storage.readDevices();
    final ts = storage.readDevicesTimestamp();
    if (cached != null) {
      state = DevicesState(
        devices: cached.devices,
        deviceLimit: cached.deviceLimit,
        deviceUsed: cached.deviceUsed,
        lastUpdatedAt: ts,
        isFromCache: true,
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.fetchDevices();
      final storage = await _ref.read(billingCacheStorageProvider.future);
      await storage.saveDevices(response);
      state = DevicesState(
        devices: response.devices,
        deviceLimit: response.deviceLimit,
        deviceUsed: response.deviceUsed,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      final errorMsg = e.toString();
      final storage = await _ref.read(billingCacheStorageProvider.future);
      final cached = storage.readDevices();
      if (cached != null) {
        state = DevicesState(
          devices: cached.devices,
          deviceLimit: cached.deviceLimit,
          deviceUsed: cached.deviceUsed,
          errorMessage: errorMsg,
          lastUpdatedAt: storage.readDevicesTimestamp(),
          isFromCache: true,
        );
      } else {
        state = DevicesState(
          devices: const [],
          errorMessage: errorMsg,
        );
      }
    }
  }

  Future<String?> addDevice(String deviceName, String platform, String appVersion) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final device = await _api.addDevice(deviceName, platform, appVersion);
      // Refresh devices and subscription
      await refresh();
      // Also refresh subscription to update device_used
      _ref.read(subscriptionStateProvider.notifier).refresh();
      return null;
    } on BillingException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return e.message;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return e.toString();
    }
  }

  Future<String?> revokeDevice(String deviceId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.revokeDevice(deviceId);
      await refresh();
      _ref.read(subscriptionStateProvider.notifier).refresh();
      return null;
    } on BillingException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return e.message;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return e.toString();
    }
  }
}

// ============================================================
// Checkout helper (not a full state, used as action)
// ============================================================

/// Notifier for checkout operations.
final checkoutStateProvider =
    StateNotifierProvider<CheckoutNotifier, AsyncValue<String?>>((ref) {
  return CheckoutNotifier(ref);
});

class CheckoutNotifier extends StateNotifier<AsyncValue<String?>> {
  CheckoutNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> checkout(String planId) async {
    state = const AsyncLoading();
    try {
      await _ref.read(billingApiClientProvider).createMockCheckout(planId);
      // Refresh subscription and history after successful checkout
      await _ref.read(subscriptionStateProvider.notifier).refresh();
      await _ref.read(billingHistoryStateProvider.notifier).refresh();
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}
