import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'biometric_service.dart';

/// State of the biometric app lock.
class AppLockState {
  const AppLockState({
    required this.isEnabled,
    required this.isLocked,
    this.isInitialized = false,
    this.isAuthenticating = false,
  });

  final bool isEnabled;
  final bool isLocked;
  final bool isInitialized;
  final bool isAuthenticating;

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    bool? isInitialized,
    bool? isAuthenticating,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    );
  }
}

/// Controller managing the biometric vault lock lifecycle using Notifier.
class AppLockNotifier extends Notifier<AppLockState> {
  BiometricSecurityService get _securityService =>
      ref.read(biometricServiceProvider);

  @override
  AppLockState build() {
    _init();
    return const AppLockState(
      isEnabled: false,
      isLocked: false,
      isInitialized: false,
    );
  }

  Future<void> _init() async {
    final enabled = await BiometricSecurityService.isBiometricEnabled();
    state = AppLockState(
      isEnabled: enabled,
      isLocked: enabled,
      isInitialized: true,
    );
  }

  /// Attempts biometric unlock.
  Future<bool> unlock({String? reason}) async {
    final enabled =
        state.isEnabled || await BiometricSecurityService.isBiometricEnabled();
    if (!enabled) {
      state = state.copyWith(isLocked: false, isInitialized: true);
      return true;
    }

    state = state.copyWith(isAuthenticating: true);
    try {
      final success = await _securityService.authenticate(
        reason: reason ?? 'Authenticate to unlock your Mindora vault',
      );
      if (success) {
        state = state.copyWith(
          isEnabled: true,
          isLocked: false,
          isInitialized: true,
          isAuthenticating: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isEnabled: true,
          isLocked: true,
          isInitialized: true,
          isAuthenticating: false,
        );
        return false;
      }
    } catch (_) {
      state = state.copyWith(
        isEnabled: true,
        isLocked: true,
        isInitialized: true,
        isAuthenticating: false,
      );
      return false;
    }
  }

  /// Enables or disables biometric lock with authentication verification.
  Future<bool> toggleBiometrics(bool enable) async {
    if (enable) {
      final canAuth = await _securityService.canAuthenticate();
      if (!canAuth) return false;

      state = state.copyWith(isAuthenticating: true);
      try {
        final success = await _securityService.authenticate(
          reason: 'Confirm biometrics to enable session vault lock',
        );
        if (success) {
          await BiometricSecurityService.setBiometricEnabled(true);
          state = state.copyWith(
            isEnabled: true,
            isLocked: false,
            isInitialized: true,
            isAuthenticating: false,
          );
          return true;
        }
        state = state.copyWith(isAuthenticating: false);
        return false;
      } catch (_) {
        state = state.copyWith(isAuthenticating: false);
        return false;
      }
    } else {
      await BiometricSecurityService.setBiometricEnabled(false);
      state = state.copyWith(
        isEnabled: false,
        isLocked: false,
        isInitialized: true,
        isAuthenticating: false,
      );
      return true;
    }
  }

  /// Locks the app manually or when backgrounded.
  void lockManually() {
    if (state.isEnabled && !state.isAuthenticating) {
      state = state.copyWith(isLocked: true);
    }
  }
}

final biometricServiceProvider = Provider<BiometricSecurityService>((ref) {
  return BiometricSecurityService();
});

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
