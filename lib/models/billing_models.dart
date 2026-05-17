/// Billing and Device data models for the Backend user-facing API.
///
/// Maps to endpoints:
/// - GET /api/v1/billing/plans
/// - GET /api/v1/billing/subscription
/// - GET /api/v1/billing/history
/// - POST /api/v1/billing/checkout
/// - GET /api/v1/devices
/// - POST /api/v1/devices
/// - DELETE /api/v1/devices/{device_id}
///
/// No payment-sensitive fields (card number, CVC, private key) are parsed.
library;

// ============================================================
// BillingPlan
// ============================================================

/// A subscription plan offered by LiveMask.
class BillingPlan {
  const BillingPlan({
    required this.planId,
    required this.name,
    required this.priceCents,
    required this.currency,
    required this.billingPeriod,
    required this.deviceLimit,
    required this.nodeAccess,
    required this.features,
  });

  factory BillingPlan.fromJson(Map<String, dynamic> json) {
    return BillingPlan(
      planId: json['plan_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceCents: json['price_cents'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      billingPeriod: json['billing_period'] as String? ?? 'monthly',
      deviceLimit: json['device_limit'] as int? ?? 0,
      nodeAccess: json['node_access'] as String? ?? 'none',
      features: _parseStringList(json['features']),
    );
  }

  final String planId;
  final String name;
  final int priceCents;
  final String currency;
  final String billingPeriod;
  final int deviceLimit;
  final String nodeAccess;
  final List<String> features;

  /// Formats price as "$9.99", "$0.00", etc.
  String get priceFormatted {
    final dollars = priceCents / 100.0;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Short description: "$9.99/mo", "Free", etc.
  String get priceDescription {
    if (priceCents == 0) return 'Free';
    final period = billingPeriod == 'yearly' ? '/yr' : '/mo';
    return '$priceFormatted$period';
  }

  bool get isFree => priceCents == 0;

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'name': name,
        'price_cents': priceCents,
        'currency': currency,
        'billing_period': billingPeriod,
        'device_limit': deviceLimit,
        'node_access': nodeAccess,
        'features': features,
      };

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return [];
  }
}

// ============================================================
// SubscriptionInfo
// ============================================================

/// The current user's subscription state.
class SubscriptionInfo {
  const SubscriptionInfo({
    this.subscriptionId,
    required this.planId,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.renewAt,
    this.cancelAtPeriodEnd = false,
    this.deviceLimit = 0,
    this.deviceUsed = 0,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      subscriptionId: json['subscription_id'] as String?,
      planId: json['plan_id'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      currentPeriodStart: json['current_period_start'] as String?,
      currentPeriodEnd: json['current_period_end'] as String?,
      renewAt: json['renew_at'] as String?,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      deviceLimit: json['device_limit'] as int? ?? 0,
      deviceUsed: json['device_used'] as int? ?? 0,
    );
  }

  final String? subscriptionId;
  final String planId;
  final String status;
  final String? currentPeriodStart;
  final String? currentPeriodEnd;
  final String? renewAt;
  final bool cancelAtPeriodEnd;
  final int deviceLimit;
  final int deviceUsed;

  bool get isActive => status == 'active';
  bool get isExpiring => status == 'expiring';
  bool get isSuspended => status == 'suspended';
  bool get isFree => planId == 'free' || planId.isEmpty;

  /// Human-readable status label.
  String get statusLabel {
    if (isActive) return 'Active';
    if (isExpiring) return 'Expiring Soon';
    if (isSuspended) return 'Suspended';
    return status;
  }

  /// Color-friendly status indicator name.
  String get statusColor {
    if (isActive) return 'green';
    if (isExpiring) return 'amber';
    if (isSuspended) return 'red';
    return 'grey';
  }

  bool get hasDeviceCapacity => deviceUsed < deviceLimit;

  Map<String, dynamic> toJson() => {
        if (subscriptionId != null) 'subscription_id': subscriptionId,
        'plan_id': planId,
        'status': status,
        if (currentPeriodStart != null) 'current_period_start': currentPeriodStart,
        if (currentPeriodEnd != null) 'current_period_end': currentPeriodEnd,
        if (renewAt != null) 'renew_at': renewAt,
        'cancel_at_period_end': cancelAtPeriodEnd,
        'device_limit': deviceLimit,
        'device_used': deviceUsed,
      };
}

// ============================================================
// BillingHistoryItem
// ============================================================

/// A single billing invoice / history entry.
class BillingHistoryItem {
  const BillingHistoryItem({
    required this.invoiceId,
    required this.planId,
    required this.amountCents,
    required this.currency,
    required this.status,
    this.paidAt,
    this.createdAt,
  });

  factory BillingHistoryItem.fromJson(Map<String, dynamic> json) {
    return BillingHistoryItem(
      invoiceId: json['invoice_id'] as String? ?? '',
      planId: json['plan_id'] as String? ?? '',
      amountCents: json['amount_cents'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? 'unknown',
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  final String invoiceId;
  final String planId;
  final int amountCents;
  final String currency;
  final String status;
  final String? paidAt;
  final String? createdAt;

  String get amountFormatted {
    final dollars = amountCents / 100.0;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  String get statusLabel {
    if (isPaid) return 'Paid';
    if (isPending) return 'Pending';
    if (isFailed) return 'Failed';
    return status;
  }

  Map<String, dynamic> toJson() => {
        'invoice_id': invoiceId,
        'plan_id': planId,
        'amount_cents': amountCents,
        'currency': currency,
        'status': status,
        if (paidAt != null) 'paid_at': paidAt,
        if (createdAt != null) 'created_at': createdAt,
      };
}

// ============================================================
// DeviceInfo
// ============================================================

/// A device registered under the user's subscription.
class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.appVersion,
    this.trusted = false,
    this.lastActiveAt,
    this.createdAt,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      platform: json['platform'] as String? ?? 'unknown',
      appVersion: json['app_version'] as String?,
      trusted: json['trusted'] as bool? ?? false,
      lastActiveAt: json['last_active_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  final String deviceId;
  final String deviceName;
  final String platform;
  final String? appVersion;
  final bool trusted;
  final String? lastActiveAt;
  final String? createdAt;

  /// Icon for the platform.
  String get platformIcon {
    switch (platform.toLowerCase()) {
      case 'ios':
      case 'macos':
        return '🍎';
      case 'android':
        return '🤖';
      case 'windows':
        return '🪟';
      case 'linux':
        return '🐧';
      default:
        return '📱';
    }
  }

  /// Human-readable platform label.
  String get platformLabel {
    switch (platform.toLowerCase()) {
      case 'ios':
        return 'iOS';
      case 'macos':
        return 'macOS';
      case 'android':
        return 'Android';
      case 'windows':
        return 'Windows';
      case 'linux':
        return 'Linux';
      default:
        return platform;
    }
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        if (appVersion != null) 'app_version': appVersion,
        'trusted': trusted,
        if (lastActiveAt != null) 'last_active_at': lastActiveAt,
        if (createdAt != null) 'created_at': createdAt,
      };
}

// ============================================================
// Response wrappers
// ============================================================

/// Response wrapper for `GET /api/v1/billing/plans`.
class BillingPlansResponse {
  const BillingPlansResponse({required this.plans});

  factory BillingPlansResponse.fromJson(Map<String, dynamic> json) {
    final list = json['plans'] as List<dynamic>?;
    return BillingPlansResponse(
      plans: list != null
          ? list
              .map((e) => BillingPlan.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final List<BillingPlan> plans;

  bool get isEmpty => plans.isEmpty;

  /// Finds a plan by its plan_id, or null.
  BillingPlan? findById(String planId) {
    try {
      return plans.firstWhere((p) => p.planId == planId);
    } catch (_) {
      return null;
    }
  }

  /// The free plan, if present.
  BillingPlan? get freePlan => plans.cast<BillingPlan?>().firstWhere(
        (p) => p!.isFree,
        orElse: () => null,
      );
}

/// Response wrapper for `GET /api/v1/billing/subscription`.
class SubscriptionResponse {
  const SubscriptionResponse({this.subscription});

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    final subJson = json['subscription'];
    if (subJson == null) return const SubscriptionResponse();
    return SubscriptionResponse(
      subscription:
          SubscriptionInfo.fromJson(subJson as Map<String, dynamic>),
    );
  }

  final SubscriptionInfo? subscription;

  /// Returns a free-tier entitlement when no subscription exists.
  SubscriptionInfo get effectiveSubscription =>
      subscription ??
      const SubscriptionInfo(
        planId: 'free',
        status: 'active',
        deviceLimit: 1,
        deviceUsed: 0,
      );
}

/// Response wrapper for `GET /api/v1/billing/history`.
class BillingHistoryResponse {
  const BillingHistoryResponse({required this.items});

  factory BillingHistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>?;
    return BillingHistoryResponse(
      items: list != null
          ? list
              .map((e) =>
                  BillingHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final List<BillingHistoryItem> items;

  bool get isEmpty => items.isEmpty;
}

/// Response wrapper for `GET /api/v1/devices`.
class DevicesResponse {
  const DevicesResponse({
    required this.devices,
    this.deviceLimit = 0,
    this.deviceUsed = 0,
  });

  factory DevicesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['devices'] as List<dynamic>?;
    return DevicesResponse(
      devices: list != null
          ? list
              .map((e) => DeviceInfo.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      deviceLimit: json['device_limit'] as int? ?? 0,
      deviceUsed: json['device_used'] as int? ?? 0,
    );
  }

  final List<DeviceInfo> devices;
  final int deviceLimit;
  final int deviceUsed;

  bool get isEmpty => devices.isEmpty;
  bool get hasCapacity => deviceUsed < deviceLimit;
}

// ============================================================
// Checkout request / response
// ============================================================

/// Request body for `POST /api/v1/billing/checkout`.
class CheckoutRequest {
  const CheckoutRequest({
    required this.planId,
    this.paymentMethod = 'mock',
  });

  final String planId;
  final String paymentMethod;

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'payment_method': paymentMethod,
      };
}

/// Response from `POST /api/v1/billing/checkout`.
class CheckoutResponse {
  const CheckoutResponse({
    required this.checkoutId,
    required this.status,
    this.redirectUrl,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      checkoutId: json['checkout_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      redirectUrl: json['redirect_url'] as String?,
    );
  }

  final String checkoutId;
  final String status;
  final String? redirectUrl;

  bool get isMockCreated => status == 'mock_created';
}

// ============================================================
// State containers for providers
// ============================================================

/// State container for billing plans.
class BillingPlansState {
  const BillingPlansState({
    this.plans = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdatedAt,
    this.isFromCache = false,
  });

  final List<BillingPlan> plans;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final bool isFromCache;

  bool get hasData => plans.isNotEmpty;
  bool get hasError => errorMessage != null;

  BillingPlansState copyWith({
    List<BillingPlan>? plans,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdatedAt,
    bool? isFromCache,
    bool clearError = false,
  }) {
    return BillingPlansState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// State container for subscription.
class SubscriptionState {
  const SubscriptionState({
    this.subscription,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdatedAt,
    this.isFromCache = false,
  });

  final SubscriptionInfo? subscription;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final bool isFromCache;

  bool get hasData => subscription != null;
  bool get hasError => errorMessage != null;
  bool get isFree => subscription?.isFree ?? true;

  SubscriptionInfo get effective =>
      subscription ??
      const SubscriptionInfo(
        planId: 'free',
        status: 'active',
        deviceLimit: 1,
        deviceUsed: 0,
      );

  SubscriptionState copyWith({
    SubscriptionInfo? subscription,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdatedAt,
    bool? isFromCache,
    bool clearError = false,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// State container for billing history.
class BillingHistoryState {
  const BillingHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdatedAt,
    this.isFromCache = false,
  });

  final List<BillingHistoryItem> items;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final bool isFromCache;

  bool get hasData => items.isNotEmpty;
  bool get isEmpty => items.isEmpty;
  bool get hasError => errorMessage != null;

  BillingHistoryState copyWith({
    List<BillingHistoryItem>? items,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdatedAt,
    bool? isFromCache,
    bool clearError = false,
  }) {
    return BillingHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// State container for devices.
class DevicesState {
  const DevicesState({
    this.devices = const [],
    this.deviceLimit = 0,
    this.deviceUsed = 0,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdatedAt,
    this.isFromCache = false,
  });

  final List<DeviceInfo> devices;
  final int deviceLimit;
  final int deviceUsed;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final bool isFromCache;

  bool get hasData => devices.isNotEmpty;
  bool get isEmpty => devices.isEmpty;
  bool get hasError => errorMessage != null;
  bool get hasCapacity => deviceUsed < deviceLimit;

  DevicesState copyWith({
    List<DeviceInfo>? devices,
    int? deviceLimit,
    int? deviceUsed,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdatedAt,
    bool? isFromCache,
    bool clearError = false,
  }) {
    return DevicesState(
      devices: devices ?? this.devices,
      deviceLimit: deviceLimit ?? this.deviceLimit,
      deviceUsed: deviceUsed ?? this.deviceUsed,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}
