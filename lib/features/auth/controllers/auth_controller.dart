import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clinic_sync/controllers/clinic_sync_providers.dart';
import '../../clinic_sync/domain/clinic_account_models.dart';
import '../data/auth_service.dart';
import '../domain/auth_state.dart';
import '../domain/auth_user.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() {
    _hydrateAuth();
    return const AuthState(status: AuthStatus.initial);
  }

  Future<void> _hydrateAuth() async {
    try {
      final user = await _service.getCurrentUser();
      final onboardingDone = await _service.hasCompletedOnboarding();

      if (!ref.mounted || state.status != AuthStatus.initial) return;
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          hasCompletedOnboarding: onboardingDone,
        );
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          user: null,
          hasCompletedOnboarding: onboardingDone,
        );
      }
    } catch (e) {
      if (!ref.mounted || state.status != AuthStatus.initial) return;
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Creates an anonymous sovereign vault.
  Future<AuthUser?> createAnonymousVault({String? codename}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.createAnonymousVault(codename: codename);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return user;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Signs in with an existing email and password.
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.signInWithEmail(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      final msg = e is FormatException ? e.message : e.toString();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Registers a new email and password vault account.
  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? codename,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.signUpWithEmail(
        email,
        password,
        codename: codename,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      final msg = e is FormatException ? e.message : e.toString();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Upgrades an anonymous vault to an email-secured cloud vault.
  Future<bool> linkEmail(
    String email,
    String password, {
    String? codename,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.linkEmailToAnonymous(
        email,
        password,
        codename: codename,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } catch (e) {
      final msg = e is FormatException ? e.message : e.toString();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Signs in to a doctor-provisioned patient account with Phone/Username + PIN.
  Future<bool> signInWithClinicCredentials(
    String identifier,
    String pinOrPassword,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final account = await ref
          .read(clinicAuthRepositoryProvider)
          .signInWithCredentials(
            identifier: identifier,
            pinOrPassword: pinOrPassword,
          );
      await _completeClinicSignIn(account);
      return true;
    } on ClinicAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Signs in immediately via a single-use Doctor QR invitation payload.
  Future<bool> signInWithClinicQr(String qrPayload) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final account = await ref
          .read(clinicAuthRepositoryProvider)
          .signInWithInviteQr(qrPayload: qrPayload);
      await _completeClinicSignIn(account);
      return true;
    } on ClinicAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> _completeClinicSignIn(ClinicPatientAccount account) async {
    final now = DateTime.now();
    final user = AuthUser(
      id: account.patientId,
      codename: account.displayName,
      authType: AuthType.clinicPin,
      clinicId: account.clinicId,
      doctorId: account.doctorId,
      doctorName: account.doctorName,
      clinicName: account.clinicName,
      loginIdentifier: account.loginIdentifier,
      createdAt: account.createdAt,
      lastActiveAt: now,
    );
    await _service.persistCurrentUser(user);
    await _service.setOnboardingCompleted(account.hasAcceptedSafetyNotice);

    final coordinator = ref.read(clinicAutoSyncCoordinatorProvider);
    await coordinator.applyProvisionedPreferences(account);

    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      hasCompletedOnboarding: account.hasAcceptedSafetyNotice,
    );
  }

  /// Marks the one-time first-login welcome/safety notice as accepted.
  Future<void> acceptClinicWelcome() async {
    final user = state.user;
    if (user != null && user.isClinicAccount) {
      await ref
          .read(clinicAuthRepositoryProvider)
          .markSafetyNoticeAccepted(patientId: user.id);
    }
    await completeOnboarding();
  }

  /// Marks onboarding as officially completed.
  Future<void> completeOnboarding() async {
    await _service.setOnboardingCompleted(true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  /// Signs out of the current session.
  Future<void> signOut() async {
    await _service.signOut();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      clearError: true,
    );
  }

  /// Permanently deletes account and local session data.
  Future<void> deleteAccount() async {
    await _service.deleteAccount();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      hasCompletedOnboarding: false,
    );
  }

  /// Clears any transient error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

