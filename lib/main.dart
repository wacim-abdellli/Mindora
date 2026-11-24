import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/localization/locale_controller.dart';
import 'app/router/app_router.dart';
import 'app/theme/display_comfort_controller.dart';
import 'app/theme/lab_theme.dart';
import 'app/theme/mind_tokens.dart';
import 'app/theme/theme_controller.dart';
import 'core/security/lock_overlay.dart';
import 'features/mind_trace/controllers/mind_trace_controller.dart';
import 'features/mind_trace/domain/mind_trace_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialThemeMode = await ThemeController.loadInitialThemeMode();
  final initialComfortMode = await DisplayComfortController.loadInitial();
  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialComfortModeProvider.overrideWithValue(initialComfortMode),
      ],
      child: const MindForensicsApp(),
    ),
  );
}

class MindForensicsApp extends ConsumerWidget {
  const MindForensicsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final activeMood = ref.watch(activeMoodProvider);
    final comfortMode = ref.watch(displayComfortProvider);
    final isArabic = locale.languageCode == 'ar';

    ref.listen<MindTraceModel?>(todayTraceProvider, (_, next) {
      if (next != null) {
        ref.read(activeMoodProvider.notifier).setMoodByKey(next.overallMood);
      }
    });

    final lightTokens = MindTokens.light
        .withMood(activeMood)
        .withComfortBoost(comfortMode);
    final darkTokens = MindTokens.dark
        .withMood(activeMood)
        .withComfortBoost(comfortMode);

    return MaterialApp.router(
      title: 'Mindora',
      debugShowCheckedModeBanner: false,
      theme: buildMindTheme(
        Brightness.light,
        tokensOverride: lightTokens,
        isArabic: isArabic,
      ),
      darkTheme: buildMindTheme(
        Brightness.dark,
        tokensOverride: darkTokens,
        isArabic: isArabic,
      ),
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final baseScale = mq.textScaler.scale(10.0) / 10.0;
        final targetScale = comfortMode
            ? (baseScale * 1.15).clamp(1.12, 1.35)
            : baseScale.clamp(0.85, 1.35);

        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(targetScale)),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: _DynamicMindThemeHost(
              activeMood: activeMood,
              isArabic: isArabic,
              comfortMode: comfortMode,
              child: LockOverlay(child: child ?? const SizedBox.shrink()),
            ),
          ),
        );
      },
    );
  }
}

/// Applies the required 200ms theme cross-fade and ~700ms dynamic mood accent
/// transition, collapsing cleanly to [Duration.zero] under reduced motion.
class _DynamicMindThemeHost extends StatefulWidget {
  const _DynamicMindThemeHost({
    required this.activeMood,
    required this.isArabic,
    required this.comfortMode,
    required this.child,
  });

  final AppMood activeMood;
  final bool isArabic;
  final bool comfortMode;
  final Widget child;

  @override
  State<_DynamicMindThemeHost> createState() => _DynamicMindThemeHostState();
}

class _DynamicMindThemeHostState extends State<_DynamicMindThemeHost> {
  Brightness? _lastBrightness;
  AppMood? _lastMood;
  Duration _currentDuration = const Duration(milliseconds: 200);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDuration();
  }

  @override
  void didUpdateWidget(covariant _DynamicMindThemeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDuration();
  }

  void _syncDuration() {
    final brightness = Theme.of(context).brightness;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      _currentDuration = Duration.zero;
    } else if (_lastBrightness != null && _lastBrightness != brightness) {
      _currentDuration = const Duration(milliseconds: 200);
    } else if (_lastMood != null && _lastMood != widget.activeMood) {
      _currentDuration = const Duration(milliseconds: 700);
    } else if (_lastBrightness == null) {
      _currentDuration = const Duration(milliseconds: 200);
    }

    _lastBrightness = brightness;
    _lastMood = widget.activeMood;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final tokens = MindTokens.forBrightness(
      brightness,
    ).withMood(widget.activeMood).withComfortBoost(widget.comfortMode);
    final themeData = buildMindTheme(
      brightness,
      tokensOverride: tokens,
      isArabic: widget.isArabic,
    );

    return AnimatedTheme(
      key: const ValueKey('mind_animated_theme'),
      data: themeData,
      duration: reduceMotion ? Duration.zero : _currentDuration,
      curve: Curves.easeInOut,
      child: widget.child,
    );
  }
}
