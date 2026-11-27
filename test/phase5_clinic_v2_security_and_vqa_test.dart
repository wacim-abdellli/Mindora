import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_forensics/app/config/app_edition.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/presentation/auth_screen.dart';
import 'package:mind_forensics/features/auth/presentation/clinic_welcome_screen.dart';
import 'package:mind_forensics/features/clinic_sync/controllers/clinic_sync_providers.dart';
import 'package:mind_forensics/features/clinician/presentation/widgets/create_patient_account_sheet.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';

class _FixedLocaleController extends LocaleController {
  _FixedLocaleController(this._locale);
  final Locale _locale;

  @override
  Locale build() => _locale;
}

void main() {
  const vqaOutDir = 'build/vqa_audit/clinic_v2';

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    final interLoader = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final f = File('assets/fonts/Inter-$weight.ttf');
      if (f.existsSync()) {
        interLoader.addFont(
          f.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))),
        );
      }
    }
    await interLoader.load();

    final arabicLoader = FontLoader('Noto Sans Arabic');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      final f = File('assets/fonts/NotoSansArabic-$weight.ttf');
      if (f.existsSync()) {
        arabicLoader.addFont(
          f.readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))),
        );
      }
    }
    await arabicLoader.load();

    final iconFile = File('assets/fonts/MaterialIcons-Regular.otf');
    if (iconFile.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons');
      iconLoader.addFont(
        iconFile
            .readAsBytes()
            .then((b) => ByteData.sublistView(Uint8List.fromList(b))),
      );
      await iconLoader.load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    AppEditionConfig.setMainEdition(MindoraEdition.patient);
  });

  Future<void> capturePng(
    WidgetTester tester,
    GlobalKey repaintKey,
    String filename,
  ) async {
    await tester.runAsync(() async {
      final boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final outFile = File('$vqaOutDir${Platform.pathSeparator}$filename');
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(bytes);
    });
  }

  Future<void> pumpMatrix({
    required WidgetTester tester,
    required Size size,
    required Locale locale,
    required double textScale,
    required Widget child,
    ProviderContainer? existingContainer,
    String? captureFilename,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repaintKey = GlobalKey();
    final host = MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light().copyWith(
        extensions: const [MindTokens.light],
      ),
      builder: (context, inner) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: RepaintBoundary(key: repaintKey, child: inner!),
        ),
      ),
      home: child,
    );

    if (existingContainer != null) {
      await tester.pumpWidget(
        UncontrolledProviderScope(container: existingContainer, child: host),
      );
    } else {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeControllerProvider.overrideWith(
              () => _FixedLocaleController(locale),
            ),
          ],
          child: host,
        ),
      );
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    if (captureFilename != null) {
      await capturePng(tester, repaintKey, captureFilename);
    }
  }

  group('Phase 5 Clinic v2 Security & 320px AR RTL VQA Matrix', () {
    test(
      'Logout wipes active session & check-in cache and enforces /auth redirect',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final authRepo = container.read(clinicAuthRepositoryProvider);
        final provision = await authRepo.createPatientAccount(
          doctorId: 'doc_mindora_primary',
          clinicId: 'clinic_tunis_01',
          doctorName: 'Dr. Amine',
          clinicName: 'Cabinet Amine',
          displayName: 'Yasmine',
          loginIdentifier: '22000111',
          ageRange: '25-44',
          preferredLanguage: 'en',
        );

        final ok = await container
            .read(authControllerProvider.notifier)
            .signInWithClinicQr(provision.qrPayload);
        expect(ok, isTrue);

        // Before accepting welcome, redirect stays at /clinic-welcome
        expect(
          await AppRouter.resolveRedirectForLocation(AppRouter.home),
          AppRouter.clinicWelcome,
        );

        await container
            .read(authControllerProvider.notifier)
            .acceptClinicWelcome();
        expect(
          await AppRouter.resolveRedirectForLocation(AppRouter.home),
          isNull,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mf_last_checkin_cache_v1', 'cached_entry');

        await container.read(authControllerProvider.notifier).signOut();

        expect(prefs.getString('mf_auth_current_user'), isNull);
        expect(prefs.getString('mf_last_checkin_cache_v1'), isNull);
        expect(prefs.getBool('mf_signed_out'), isTrue);
        expect(
          await AppRouter.resolveRedirectForLocation(AppRouter.home),
          AppRouter.auth,
        );
      },
    );

    testWidgets(
      'AuthScreen passes 412px EN & 320px AR RTL 1.35x without overflow or a11y failures',
      (tester) async {
        await pumpMatrix(
          tester: tester,
          size: const Size(412, 915),
          locale: const Locale('en'),
          textScale: 1.0,
          child: const AuthScreen(),
          captureFilename: '01_auth_clinic_en.png',
        );

        await pumpMatrix(
          tester: tester,
          size: const Size(320, 640),
          locale: const Locale('ar'),
          textScale: 1.35,
          child: const AuthScreen(),
          captureFilename: '02_auth_clinic_ar_rtl_320.png',
        );
      },
    );

    testWidgets(
      'ClinicWelcomeScreen passes 320px AR RTL 1.35x without overflow or a11y failures',
      (tester) async {
        await pumpMatrix(
          tester: tester,
          size: const Size(320, 640),
          locale: const Locale('ar'),
          textScale: 1.35,
          child: const ClinicWelcomeScreen(),
          captureFilename: '03_clinic_welcome_ar_rtl_320.png',
        );
      },
    );

    testWidgets(
      'Minimal SettingsScreen passes 320px AR RTL 1.35x without overflow or a11y failures',
      (tester) async {
        await pumpMatrix(
          tester: tester,
          size: const Size(320, 640),
          locale: const Locale('ar'),
          textScale: 1.35,
          child: const SettingsScreen(),
          captureFilename: '04_settings_minimal_ar_rtl_320.png',
        );
      },
    );

    testWidgets(
      'CreatePatientAccountSheet form (320px AR RTL 1.35x) and Handover QR (412px EN) pass without overflow or a11y failures',
      (tester) async {
        await pumpMatrix(
          tester: tester,
          size: const Size(320, 640),
          locale: const Locale('ar'),
          textScale: 1.35,
          child: const Scaffold(body: CreatePatientAccountSheet()),
        );

        final container = ProviderContainer(
          overrides: [
            localeControllerProvider.overrideWith(
              () => _FixedLocaleController(const Locale('en')),
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = await container
            .read(clinicAuthRepositoryProvider)
            .createPatientAccount(
              doctorId: 'doc_mindora_primary',
              clinicId: 'clinic_tunis_01',
              doctorName: 'Dr. Amine',
              clinicName: 'Cabinet Amine',
              displayName: 'Samira K.',
              loginIdentifier: '22987654',
              ageRange: '65+',
              preferredLanguage: 'ar',
              customTempPin: '482910',
            );

        await pumpMatrix(
          tester: tester,
          size: const Size(412, 915),
          locale: const Locale('en'),
          textScale: 1.0,
          existingContainer: container,
          child: Scaffold(
            body: CreatePatientAccountSheet(initialHandover: result),
          ),
          captureFilename: '05_create_patient_handover_qr.png',
        );
        expect(find.text('482910'), findsOneWidget);
        expect(
          find.text(const AppStrings('en').patientAccessReadyTitle),
          findsOneWidget,
        );
      },
    );
  });
}
