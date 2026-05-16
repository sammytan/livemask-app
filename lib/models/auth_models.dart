/// Authentication-related data models matching the auth-rbac.md contract.

/// User summary — subset of fields returned by `/api/v1/me`.
class UserSummary {
  const UserSummary({
    required this.userId,
    required this.email,
    this.displayName,
    required this.roles,
    required this.permissions,
    this.subscriptionStatus,
    required this.createdAt,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      subscriptionStatus: json['subscription_status'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        if (displayName != null) 'display_name': displayName,
        'roles': roles,
        'permissions': permissions,
        if (subscriptionStatus != null)
          'subscription_status': subscriptionStatus,
        'created_at': createdAt,
      };

  final String userId;
  final String email;
  final String? displayName;
  final List<String> roles;
  final List<String> permissions;
  final String? subscriptionStatus;
  final String createdAt;

  /// Whether the user has any admin/sponsor/ambassador role.
  bool get isAdmin => roles.any((r) =>
      r == 'admin' ||
      r == 'super_admin' ||
      r == 'ops_operator' ||
      r == 'support_agent' ||
      r == 'finance_operator' ||
      r == 'auditor');

  @override
  String toString() => 'UserSummary(userId=$userId, email=$email, '
      'roles=$roles, permissions=$permissions)';
}

/// Token pair returned by login/refresh endpoints.
class TokenPair {
  const TokenPair({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }

  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  bool get hasValidAccessToken => accessToken.isNotEmpty;

  @override
  String toString() =>
      'TokenPair(accessToken=***${accessToken.isNotEmpty ? accessToken.substring(accessToken.length > 10 ? accessToken.length - 4 : 0) : ''})';
}

/// Login request body.
class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    required this.clientType,
    this.mfaCode,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'client_type': clientType,
        if (mfaCode != null) 'mfa_code': mfaCode,
      };

  final String email;
  final String password;
  final String clientType;
  final String? mfaCode;
}

/// Login response body.
class LoginResponse {
  const LoginResponse({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: UserSummary.fromJson(
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int? ?? 0,
    );
  }

  final UserSummary user;
  final String accessToken;
  final String? refreshToken;
  final int expiresIn;
}

/// Register request body.
class RegisterRequest {
  const RegisterRequest({
    required this.requestId,
    required this.email,
    required this.password,
    this.displayName,
    this.referralCode,
    required this.clientType,
  });

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'email': email,
        'password': password,
        'client_type': clientType,
        if (displayName != null) 'display_name': displayName,
        if (referralCode != null) 'referral_code': referralCode,
      };

  final String requestId;
  final String email;
  final String password;
  final String? displayName;
  final String? referralCode;
  final String clientType;
}

/// Register response body.
class RegisterResponse {
  const RegisterResponse({
    required this.userId,
    required this.emailVerificationRequired,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json['user_id'] as String? ?? '',
      emailVerificationRequired:
          json['email_verification_required'] as bool? ?? false,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }

  final String userId;
  final bool emailVerificationRequired;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
}

/// Authentication state enum for the app.
enum AuthState {
  /// No session exists — user needs to log in.
  unauthenticated,

  /// Session is present and valid.
  authenticated,

  /// Auth operation in progress (login, refresh, logout).
  loading,

  /// Auth operation failed.
  error,
}

/// Full auth state held by the auth notifier.
class AuthNotifierState {
  const AuthNotifierState({
    this.status = AuthState.unauthenticated,
    this.user,
    this.errorMessage,
  });

  final AuthState status;
  final UserSummary? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthState.authenticated;
  bool get isLoading => status == AuthState.loading;
  bool get hasError => status == AuthState.error;

  static const initial = AuthNotifierState(status: AuthState.unauthenticated);

  AuthNotifierState copyWith({
    AuthState? status,
    UserSummary? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthNotifierState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
