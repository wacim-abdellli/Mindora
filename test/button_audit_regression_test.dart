import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/safety/support_button.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/presentation/auth_screen.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinic_sync/domain/clinic_account_models.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/mind_qr_scanner_sheet.dart';
import 'package:mind_forensics/features/support/presentation/contextual_support_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
  });

  group('Button Audit Regression Tests', () {
    testWidgets(
      'AuthScreen -> Scan doctor QR -> Paste text code switches to inline paste form and authenticates cleanly',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final provision = await container
            .read(clinicAuthRepositoryProvider)
            .createPatientAccount(
              doctorId: 'doc_mindora_primary',
              clinicId: 'clinic_tunis_01',
              doctorName: 'Dr. Amine',
              clinicName: 'Cabinet Amine',
              displayName: 'Leila',
              loginIdentifier: '22555666',
              ageRange: '25-44',
              preferredLanguage: 'en',
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: const AuthScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Tap "Scan doctor's QR"
        await tester.tap(find.byKey(const ValueKey('auth-scan-qr-btn')));
        await tester.pumpAndSettle();
        expect(find.byType(MindQrScannerSheet), findsOneWidget);

        // 2. Tap "Paste text code" -> MUST stay open in inline paste mode
        final pasteModeBtn = find.byKey(const ValueKey('qr-paste-mode-btn'));
        expect(pasteModeBtn, findsOneWidget);
        await tester.ensureVisible(pasteModeBtn);
        await tester.tap(pasteModeBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('qr-paste-code-field')),
          findsOneWidget,
        );

        // 3. Invalid prefix displays error visibly and does not dismiss
        const en = AppStrings('en');
        await tester.enterText(
          find.byKey(const ValueKey('qr-paste-code-field')),
          'INVALID-CODE',
        );
        await tester.tap(find.byKey(const ValueKey('qr-paste-submit-btn')));
        await tester.pumpAndSettle();
        expect(
          find.text(en.qrScannerWrongPrefixError(ClinicInvitePayload.qrPrefix)),
          findsOneWidget,
        );
        expect(find.byType(MindQrScannerSheet), findsOneWidget);

        // 4. Valid invite QR payload signs patient in seamlessly
        await tester.enterText(
          find.byKey(const ValueKey('qr-paste-code-field')),
          provision.qrPayload,
        );
        await tester.tap(find.byKey(const ValueKey('qr-paste-submit-btn')));
        await tester.pumpAndSettle();

        expect(find.byType(MindQrScannerSheet), findsNothing);
        expect(container.read(authControllerProvider).isAuthenticated, isTrue);
        expect(
          container.read(authControllerProvider).user?.codename,
          'Leila',
        );
      },
    );

    testWidgets(
      'AuthScreen shows error banner prominently above Card 1 on invalid pasted fallback QR',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: const AuthScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        await tester.tap(find.text(en.enterQrCodeFallbackBtn));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'bad-qr');
        await tester.tap(find.widgetWithText(FilledButton, en.logInBtn));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('auth-error-banner')), findsOneWidget);
      },
    );

    testWidgets(
      'ContextualSupportSheet crisis button safely opens SupportModalSheet after dismissing itself',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: const [MindTokens.light],
              ),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => Center(
                    child: ElevatedButton(
                      onPressed: () => ContextualSupportSheet.show(ctx),
                      child: const Text('Open Support'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Support'));
        await tester.pumpAndSettle();

        const en = AppStrings('en');
        final crisisTile = find.text(en.needCrisisHelp);
        await tester.ensureVisible(crisisTile);
        await tester.tap(crisisTile);
        await tester.pumpAndSettle();

        expect(find.byType(SupportModalSheet), findsOneWidget);
      },
    );
  });
}
