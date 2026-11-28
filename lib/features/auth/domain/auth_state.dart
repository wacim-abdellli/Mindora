import 'auth_user.dart';

/// The authentication status lifecycle.
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

/// The state holder for the authentication controller.
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.hasCompletedOnboarding = false,
    this.signedInViaQr = false,
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool hasCompletedOnboarding;
  final bool signedInViaQr;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  bool get isAnonymous => user?.isAnonymous ?? true;

  bool get isLockedOut =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  int get lockoutRemainingSeconds {
    if (lockoutUntil == null) return 0;
    final diff = lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    bool? hasCompletedOnboarding,
    bool? signedInViaQr,
    int? failedAttempts,
    DateTime? lockoutUntil,
    bool clearError = false,
    bool clearUser = false,
    bool clearLockout = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      signedInViaQr: signedInViaQr ?? this.signedInViaQr,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
    );
  }
}

