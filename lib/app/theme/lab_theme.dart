import 'package:flutter/material.dart';

import 'mind_tokens.dart';

/// Builds unified Light ("Dawn") and Dark ("Vercel") [ThemeData] exclusively from [MindTokens].
///
/// Zero raw color literals exist in this file; all visual properties map from
/// [MindTokens]. Set [isArabic] to `true` to enforce `letterSpacing: 0.0` so
/// Arabic cursive glyph joining never breaks.
ThemeData buildMindTheme(
  Brightness brightness, {
  MindTokens? tokensOverride,
  bool isArabic = false,
}) {
  final tokens = tokensOverride ?? MindTokens.forBrightness(brightness);
  final isDark = brightness == Brightness.dark;
  final textTheme = _buildTextTheme(tokens, isArabic: isArabic);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: tokens.primary,
    onPrimary: tokens.onPrimary,
    secondary: tokens.m1,
    onSecondary: tokens.onMood,
    error: tokens.safety,
    onError: tokens.onSafety,
    surface: tokens.surface,
    onSurface: tokens.ink,
    surfaceContainerLowest: tokens.bg,
    surfaceContainerLow: tokens.surface,
    surfaceContainer: tokens.surface2,
    surfaceContainerHigh: tokens.surface3,
    surfaceContainerHighest: tokens.surface3,
    onSurfaceVariant: tokens.ink2,
    outline: tokens.line,
    outlineVariant: tokens.lineStrong,
    shadow: isDark ? Colors.transparent : tokens.ink,
    scrim: tokens.scrim,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: LabTheme.fontFamily,
    fontFamilyFallback: LabTheme.fontFallback,
    scaffoldBackgroundColor: tokens.bg,
    canvasColor: tokens.bg,
    dividerColor: tokens.line,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: tokens.surfaceHover,
    focusColor: tokens.focusRing,
    colorScheme: colorScheme,
    textTheme: textTheme,
    extensions: [tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bg,
      foregroundColor: tokens.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: tokens.ink),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: tokens.ink),
    ),
    cardTheme: CardThemeData(
      color: tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.line, width: 1.0),
      ),
    ),
    dividerTheme: DividerThemeData(color: tokens.line, thickness: 1, space: 1),
    sliderTheme: SliderThemeData(
      trackHeight: 14.0,
      activeTrackColor: tokens.m1,
      inactiveTrackColor: tokens.surface2,
      thumbColor: MindTokens.pureWhiteConstant,
      overlayColor: Colors.transparent,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
      trackShape: const RoundedRectSliderTrackShape(),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.switchThumbOn;
        }
        return tokens.ink3;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.switchOnTrack;
        }
        return tokens.switchOffTrack;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.accentInk;
        }
        return tokens.line;
      }),
      trackOutlineWidth: const WidgetStatePropertyAll(1.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surface2,
      hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.ink3),
      labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.inputRadius),
        borderSide: BorderSide(color: tokens.line, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.inputRadius),
        borderSide: BorderSide(color: tokens.line, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.inputRadius),
        borderSide: BorderSide(color: tokens.focusRing, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.inputRadius),
        borderSide: BorderSide(color: tokens.safety, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.inputRadius),
        borderSide: BorderSide(color: tokens.safety, width: 2.0),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      barrierColor: tokens.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.line, width: 1.0),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: tokens.ink),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.ink2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surface,
      modalBackgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBarrierColor: tokens.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.sheetRadius),
        ),
        side: BorderSide(color: tokens.line, width: 1.0),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        minimumSize: const Size(0, 56),
        elevation: 0,
        splashFactory: NoSplash.splashFactory,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.ink,
        minimumSize: const Size(0, 48),
        elevation: 0,
        splashFactory: NoSplash.splashFactory,
        side: BorderSide(color: tokens.line, width: 1.5),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.ink,
        minimumSize: const Size(48, 48),
        splashFactory: NoSplash.splashFactory,
        textStyle: textTheme.labelLarge,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: tokens.bg,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.inputRadius),
      ),
    ),
  );
}

TextTheme _buildTextTheme(MindTokens tokens, {required bool isArabic}) {
  double? track(double value) => isArabic ? 0.0 : value;

  TextStyle style({
    required double size,
    required FontWeight weight,
    required double height,
    required Color color,
    double letterSpacing = 0.0,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: LabTheme.fontFamily,
      fontFamilyFallback: LabTheme.fontFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: track(letterSpacing),
      fontStyle: fontStyle,
      color: color,
    );
  }

  return TextTheme(
    displayLarge: style(
      size: 31,
      weight: FontWeight.w800,
      height: 1.08,
      letterSpacing: -0.9,
      color: tokens.ink,
    ),
    headlineLarge: style(
      size: 31,
      weight: FontWeight.w800,
      height: 1.12,
      letterSpacing: -0.8,
      color: tokens.ink,
    ),
    headlineMedium: style(
      size: 21,
      weight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.5,
      color: tokens.ink,
    ),
    headlineSmall: style(
      size: 18,
      weight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
      color: tokens.ink,
    ),
    titleLarge: style(
      size: 17,
      weight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.2,
      color: tokens.ink,
    ),
    titleMedium: style(
      size: 16,
      weight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.15,
      color: tokens.ink,
    ),
    titleSmall: style(
      size: 14,
      weight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0.0,
      color: tokens.ink2,
    ),
    bodyLarge: style(
      size: 16.0,
      weight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.0,
      color: tokens.ink,
    ),
    bodyMedium: style(
      size: 15.5,
      weight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.0,
      color: tokens.ink2,
    ),
    bodySmall: style(
      size: 13.5,
      weight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0.0,
      color: tokens.ink3,
    ),
    labelLarge: style(
      size: 16.0,
      weight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.1,
      color: tokens.ink,
    ),
    labelMedium: style(
      size: 14.0,
      weight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.0,
      color: tokens.ink2,
    ),
    labelSmall: style(
      size: 12.5,
      weight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0.0,
      color: tokens.ink3,
    ),
  );
}

/// Centralized typography helper preserving bundled Inter + Noto Sans Arabic fallback.
abstract final class LabTheme {
  static const String fontFamily = 'Inter';
  static const List<String> fontFallback = ['Noto Sans Arabic'];

  /// Returns an Inter text style with Noto Sans Arabic fallback for RTL safety.
  ///
  /// When [isArabic] is true, [letterSpacing] is forced to `0.0` so Arabic
  /// cursive ligatures never break.
  static TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? height,
    double? letterSpacing,
    Color? color,
    bool isArabic = false,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: height,
      letterSpacing: isArabic ? 0.0 : letterSpacing,
      color: color,
    );
  }
}
