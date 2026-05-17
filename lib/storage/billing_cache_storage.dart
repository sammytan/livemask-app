import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/billing_models.dart';

/// Persistent cache for billing/device data using SharedPreferences.
///
/// Provides offline fallback when the Backend is unreachable.
class BillingCacheStorage {
  BillingCacheStorage({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _plansKey = 'billing_cache_plans';
  static const String _plansTsKey = 'billing_cache_plans_ts';
  static const String _subKey = 'billing_cache_subscription';
  static const String _subTsKey = 'billing_cache_subscription_ts';
  static const String _historyKey = 'billing_cache_history';
  static const String _historyTsKey = 'billing_cache_history_ts';
  static const String _devicesKey = 'billing_cache_devices';
  static const String _devicesTsKey = 'billing_cache_devices_ts';

  // ---- Plans ----

  Future<void> savePlans(BillingPlansResponse response) async {
    final jsonStr =
        jsonEncode(response.plans.map((p) => p.toJson()).toList());
    await _prefs.setString(_plansKey, jsonStr);
    await _prefs.setInt(_plansTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  BillingPlansResponse? readPlans() {
    final raw = _prefs.getString(_plansKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return BillingPlansResponse(
        plans: decoded
            .map((e) => BillingPlan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? readPlansTimestamp() {
    final ms = _prefs.getInt(_plansTsKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // ---- Subscription ----

  Future<void> saveSubscription(SubscriptionResponse response) async {
    if (response.subscription != null) {
      await _prefs.setString(_subKey, jsonEncode(response.subscription!.toJson()));
    } else {
      await _prefs.remove(_subKey);
    }
    await _prefs.setInt(_subTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  SubscriptionResponse? readSubscription() {
    final raw = _prefs.getString(_subKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return SubscriptionResponse(
        subscription:
            SubscriptionInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? readSubscriptionTimestamp() {
    final ms = _prefs.getInt(_subTsKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // ---- History ----

  Future<void> saveHistory(BillingHistoryResponse response) async {
    final jsonStr =
        jsonEncode(response.items.map((i) => i.toJson()).toList());
    await _prefs.setString(_historyKey, jsonStr);
    await _prefs.setInt(_historyTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  BillingHistoryResponse? readHistory() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return BillingHistoryResponse(
        items: decoded
            .map((e) => BillingHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? readHistoryTimestamp() {
    final ms = _prefs.getInt(_historyTsKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // ---- Devices ----

  Future<void> saveDevices(DevicesResponse response) async {
    final jsonStr = jsonEncode({
      'devices': response.devices.map((d) => d.toJson()).toList(),
      'device_limit': response.deviceLimit,
      'device_used': response.deviceUsed,
    });
    await _prefs.setString(_devicesKey, jsonStr);
    await _prefs.setInt(_devicesTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  DevicesResponse? readDevices() {
    final raw = _prefs.getString(_devicesKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return DevicesResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  DateTime? readDevicesTimestamp() {
    final ms = _prefs.getInt(_devicesTsKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // ---- Bulk ----

  Future<void> clearCache() async {
    await _prefs.remove(_plansKey);
    await _prefs.remove(_plansTsKey);
    await _prefs.remove(_subKey);
    await _prefs.remove(_subTsKey);
    await _prefs.remove(_historyKey);
    await _prefs.remove(_historyTsKey);
    await _prefs.remove(_devicesKey);
    await _prefs.remove(_devicesTsKey);
  }
}
