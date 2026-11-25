import 'package:flutter/material.dart';

import '../../features/investigation/domain/label_type.dart';

/// The six expressive mood states sharing identical vivid colors across
/// Sunrise (Default Warm Light) and Twilight (Optional Deep Indigo Night) themes.
///
/// Always paired with a drawn vector [MoodFace] or icon and plain text label —
/// never represented by color alone and never using Unicode emojis.
enum AppMood {
  good(key: 'good', icon: Icons.wb_sunny_outlined),
  calm(key: 'calm', icon: Icons.eco_outlined),
  anxious(key: 'anxious', icon: Icons.waves_rounded),
  frustrated(key: 'frustrated', icon: Icons.local_fire_department_rounded),
  heavy(key: 'heavy', icon: Icons.cloud_outlined),
  restless(key: 'restless', icon: Icons.air_rounded);

  const AppMood({required this.key, required this.icon});

  final String key;
  final IconData icon;

  /// Resolves a mood enum from its string storage/controller key.
  static AppMood fromKey(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == 'happy' || normalized == 'joyful') {
      return AppMood.good;
    }
    for (final value in AppMood.values) {
      if (value.key == normalized) {
        return value;
      }
    }
    return AppMood.calm;
  }
}

/// Unified design tokens powering Mindora across Sunrise (Warm Daylight) and
/// Twilight (Deep Indigo Night) themes.
///
/// Feature screens and shared widgets read colors, shapes, spacing, and dynamic
/// mood tints exclusively from `context.tokens` (never raw `Color(0x...)` or
/// `Colors.*`).
@immutable
class MindTokens extends ThemeExtension<MindTokens> {
  const MindTokens({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.primary,
    required this.onPrimary,
    required this.primaryDeep,
    required this.onMood,
    required this.safety,
    required this.safetySoft,
    required this.glow,
    required this.orbGlowFactor,
    required this.shadows,
    required this.navGlass,
    required this.scrim,
    required this.focusRing,
    required this.m1,
    required this.m2,
    required this.tintCard,
    required this.tintSelected,
    required this.tintBlob,
    required this.dayBaseTint,
    required this.dayStepTint,
    required this.navActiveTint,
    required this.switchOnTrackTint,
    this.cardRadius = 24.0,
    this.tileRadius = 22.0,
    this.rowRadius = 20.0,
    this.buttonRadius = 20.0,
    this.chipRadius = 99.0,
    this.inputRadius = 16.0,
    this.iconButtonRadius = 16.0,
    this.sheetRadius = 28.0,
    this.screenPadding = 16.0,
    this.blockGap = 16.0,
  });

  final Brightness brightness;

  // Neutral surface & ink ladder
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color ink2;
  final Color ink3;

  // Alive primary action palette (Violet in Sunrise / Luminous Lilac in Twilight)
  final Color primary;
  final Color onPrimary;
  final Color primaryDeep;
  final Color onMood;

  // Safety / Crisis & destructive surfaces ONLY
  final Color safety;
  final Color safetySoft;

  // Ambient glow & elevation
  final double glow;
  final double orbGlowFactor;
  final List<BoxShadow> shadows;
  final Color navGlass;
  final Color scrim;
  final Color focusRing;

  // Dynamic active mood accent (default Calm, animates ~700ms on mood change)
  final Color m1;
  final Color m2;

  // Theme-calibrated alpha percentages for alphaBlend tints
  final double tintCard;
  final double tintSelected;
  final double tintBlob;
  final double dayBaseTint;
  final double dayStepTint;
  final double navActiveTint;
  final double switchOnTrackTint;

  // Shared geometry & spacing (8px grid)
  final double cardRadius;
  final double tileRadius;
  final double rowRadius;
  final double buttonRadius;
  final double chipRadius;
  final double inputRadius;
  final double iconButtonRadius;
  final double sheetRadius;
  final double screenPadding;
  final double blockGap;

  bool get isDark => brightness == Brightness.dark;

  // ---------------------------------------------------------------------------
  // Canonical Vivid Mood Palette (WCAG AA+ >= 7:1 with Carbon Ink, Zero Purple)
  // ---------------------------------------------------------------------------
  static const Color moodGood = Color(0xFFFFC93C);
  static const Color moodGoodHighlight = Color(0xFFFFE58F);

  static const Color moodCalm = Color(0xFF2DD4BF);
  static const Color moodCalmHighlight = Color(0xFF99F6E4);

  static const Color moodAnxious = Color(0xFF38BDF8);
  static const Color moodAnxiousHighlight = Color(0xFFBAE6FD);

  static const Color moodFrustrated = Color(0xFFFF7A59);
  static const Color moodFrustratedHighlight = Color(0xFFFFB49E);

  static const Color moodHeavy = Color(0xFF94A3B8);
  static const Color moodHeavyHighlight = Color(0xFFCBD5E1);

  static const Color moodRestless = Color(0xFFFBBF24);
  static const Color moodRestlessHighlight = Color(0xFFFDE68A);

  static const Color onMoodConstant = Color(0xFF111114);
  static const Color pureWhiteConstant = Color(0xFFFFFFFF);
  static const Color pureBlackConstant = Color(0xFF09090B);

  // Decorative wave/wireframe artwork constants (zero purple)
  static const Color waveSkyTop = Color(0xFFFAF9F6);
  static const Color waveSkyBottom = Color(0xFFF3F1EC);
  static const Color waveSunHighlight = Color(0xFFFFFDF5);
  static const Color waveSunGlow = Color(0xFFFFEAC0);
  static const Color waveSunCore = Color(0xFFFFF9E6);
  static const Color waveRidgeLightTop = Color(0xFF5EEAD4);
  static const Color waveRidgeLightBottom = Color(0xFF2DD4BF);
  static const Color waveRidgeMidTop = Color(0xFF0D9488);
  static const Color waveRidgeMidBottom = Color(0xFF0F766E);
  static const Color waveRidgeDeepBottom = Color(0xFF111114);

  static const Color wireframeGlowInner = Color(0xFFFFE58F);
  static const Color wireframeGlowOuter = Color(0xFF99F6E4);
  static const Color wireframeRingOuter = Color(0xFF94A3B8);
  static const Color wireframeRingInner = Color(0xFFCBD5E1);
  static const Color wireframeFold = Color(0xFFF1F5F9);
  static const Color wireframeSulcus = Color(0xFF38BDF8);
  static const Color wireframeNode = Color(0xFFFFFDF5);
  static const Color orbWarmHighlight = Color(0xFFFAF9F6);

  // ---------------------------------------------------------------------------
  // Warm Alabaster Daylight (Default Light) constants — Zero Purple, WCAG AAA
  // ---------------------------------------------------------------------------
  static const Color lightBg = Color(0xFFFAF9F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF3F1EC);
  static const Color lightSurface3 = Color(0xFFEBE8E1);
  static const Color lightLine = Color.fromRGBO(17, 17, 20, 0.09);
  static const Color lightLineStrong = Color.fromRGBO(17, 17, 20, 0.18);
  static const Color lightInk = Color(0xFF111114);
  static const Color lightInk2 = Color(0xFF52525B);
  static const Color lightInk3 = Color(0xFF5E5E68);
  static const Color lightPrimary = Color(0xFF111114);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryDeep = Color(0xFF27272A);
  static const Color lightSafety = Color(0xFFBE123C);
  static const Color lightSafetySoft = Color(0xFFFFF1F2);
  static const Color lightNavGlass = Color.fromRGBO(250, 249, 246, 0.92);
  static const Color lightScrim = Color.fromRGBO(9, 9, 11, 0.45);
  static const Color lightFocusRingDefault = Color(0xFF0D9488);

  // ---------------------------------------------------------------------------
  // Clean Vercel Obsidian-Zinc Dark constants — Zero Purple, Zero #000000
  // ---------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF111114);
  static const Color darkSurface2 = Color(0xFF18181C);
  static const Color darkSurface3 = Color(0xFF222228);
  static const Color darkLine = Color.fromRGBO(255, 255, 255, 0.09);
  static const Color darkLineStrong = Color.fromRGBO(255, 255, 255, 0.18);
  static const Color darkInk = Color(0xFFFAFAFA);
  static const Color darkInk2 = Color(0xFFA1A1AA);
  static const Color darkInk3 = Color(0xFF8B8B96);
  static const Color darkPrimary = Color(0xFFFAFAFA);
  static const Color darkOnPrimary = Color(0xFF09090B);
  static const Color darkPrimaryDeep = Color(0xFFE4E4E7);
  static const Color darkSafety = Color(0xFFFB7185);
  static const Color darkSafetySoft = Color(0xFF2C1219);
  static const Color darkNavGlass = Color.fromRGBO(17, 17, 20, 0.92);
  static const Color darkScrim = Color.fromRGBO(4, 4, 6, 0.70);
  static const Color darkFocusRing = Color(0xFF2DD4BF);

  /// Warm Alabaster Daylight token preset.
  static const MindTokens light = MindTokens(
    brightness: Brightness.light,
    bg: lightBg,
    surface: lightSurface,
    surface2: lightSurface2,
    surface3: lightSurface3,
    line: lightLine,
    lineStrong: lightLineStrong,
    ink: lightInk,
    ink2: lightInk2,
    ink3: lightInk3,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    primaryDeep: lightPrimaryDeep,
    onMood: onMoodConstant,
    safety: lightSafety,
    safetySoft: lightSafetySoft,
    glow: 0.20,
    orbGlowFactor: 1.0,
    shadows: [
      BoxShadow(
        color: Color.fromRGBO(17, 17, 20, 0.04),
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color.fromRGBO(17, 17, 20, 0.08),
        blurRadius: 24,
        spreadRadius: -8,
        offset: Offset(0, 10),
      ),
    ],
    navGlass: lightNavGlass,
    scrim: lightScrim,
    focusRing: lightFocusRingDefault,
    m1: moodCalm,
    m2: moodCalmHighlight,
    tintCard: 0.14,
    tintSelected: 0.22,
    tintBlob: 0.36,
    dayBaseTint: 0.26,
    dayStepTint: 0.05,
    navActiveTint: 0.16,
    switchOnTrackTint: 0.55,
  );

  /// Clean Vercel Obsidian-Zinc Dark token preset — zero purple, zero #000000.
  static const MindTokens dark = MindTokens(
    brightness: Brightness.dark,
    bg: darkBg,
    surface: darkSurface,
    surface2: darkSurface2,
    surface3: darkSurface3,
    line: darkLine,
    lineStrong: darkLineStrong,
    ink: darkInk,
    ink2: darkInk2,
    ink3: darkInk3,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    primaryDeep: darkPrimaryDeep,
    onMood: onMoodConstant,
    safety: darkSafety,
    safetySoft: darkSafetySoft,
    glow: 0.14,
    orbGlowFactor: 0.72,
    shadows: [],
    navGlass: darkNavGlass,
    scrim: darkScrim,
    focusRing: darkFocusRing,
    m1: moodCalm,
    m2: moodCalmHighlight,
    tintCard: 0.10,
    tintSelected: 0.18,
    tintBlob: 0.28,
    dayBaseTint: 0.20,
    dayStepTint: 0.04,
    navActiveTint: 0.18,
    switchOnTrackTint: 0.55,
  );

  /// Returns preset tokens for [brightness].
  static MindTokens forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Canonical vivid mood color `c1` for [mood].
  static Color moodColor(AppMood mood) {
    return switch (mood) {
      AppMood.good => moodGood,
      AppMood.calm => moodCalm,
      AppMood.anxious => moodAnxious,
      AppMood.frustrated => moodFrustrated,
      AppMood.heavy => moodHeavy,
      AppMood.restless => moodRestless,
    };
  }

  /// Canonical vivid mood highlight `c2` for [mood].
  static Color moodHighlight(AppMood mood) {
    return switch (mood) {
      AppMood.good => moodGoodHighlight,
      AppMood.calm => moodCalmHighlight,
      AppMood.anxious => moodAnxiousHighlight,
      AppMood.frustrated => moodFrustratedHighlight,
      AppMood.heavy => moodHeavyHighlight,
      AppMood.restless => moodRestlessHighlight,
    };
  }

  /// Canonical mood icon (always paired with mood color & label).
  static IconData moodIcon(AppMood mood) => mood.icon;

  /// Convenience lookup by string mood key (`'good'`, `'calm'`, `'anxious'`, ...).
  static Color moodColorByKey(String? key) => moodColor(AppMood.fromKey(key));

  /// Convenience highlight lookup by string mood key.
  static Color moodHighlightByKey(String? key) =>
      moodHighlight(AppMood.fromKey(key));

  /// Computes alpha-blended tint over [surface]: `alphaBlend(accent @ opacity, surface)`.
  Color tint(Color accent, double opacity) => Color.alphaBlend(
    accent.withValues(alpha: opacity.clamp(0.0, 1.0)),
    surface,
  );

  /// Active mood card tint (14% Sunrise / 10% Twilight).
  Color get cardTint => tint(m1, tintCard);

  /// Active mood selected chip/tile tint (22% Sunrise / 18% Twilight).
  Color get selectedTint => tint(m1, tintSelected);

  /// Computes selected chip/tile background for an arbitrary [accent] color.
  Color selectedTintFor(Color accent) => tint(accent, tintSelected);

  /// Computes card tint background for an arbitrary [accent] color.
  Color cardTintFor(Color accent) => tint(accent, tintCard);

  /// Active mood icon blob tint (36% Sunrise / 28% Twilight).
  Color get blobTint => tint(m1, tintBlob);

  /// Computes icon blob background for an arbitrary [accent] color.
  Color blobTintFor(Color accent) => tint(accent, tintBlob);

  /// Soft primary tint for violet highlights & active pill fills.
  Color get primarySoft => tint(primary, isDark ? 0.18 : 0.12);

  /// Computes mood day calendar fill (`26% + 5%*intensity` Sunrise / `20% + 4%*intensity` Twilight).
  Color moodDayColor(Color moodColorValue, int intensity) {
    final clamped = intensity.clamp(0, 10);
    final opacity = (dayBaseTint + dayStepTint * clamped).clamp(0.0, 1.0);
    return tint(moodColorValue, opacity);
  }

  /// Returns a copy driven by [mood] with updated `m1` and `m2`.
  MindTokens withMood(AppMood mood) {
    final nextM1 = moodColor(mood);
    final nextM2 = moodHighlight(mood);
    return copyWith(m1: nextM1, m2: nextM2);
  }

  // ---------------------------------------------------------------------------
  // Token-Driven Component Helpers
  // ---------------------------------------------------------------------------

  /// Soft colored elevation shadow under primary CTAs in Sunrise; clean flat in Twilight.
  List<BoxShadow> get primaryButtonShadows => !isDark
      ? [
          BoxShadow(
            color: primary.withValues(alpha: 0.24),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ]
      : const [];

  /// Soft button surface: warm peach well in Sunrise, soft violet well in Twilight.
  Color get softButtonBg => surface2;

  /// Soft button border: subtle strong hairline for instant tappability affordance.
  Color get softButtonBorder => lineStrong;

  /// Border color for active segments.
  Color get segmentedActiveBorder => isDark ? lineStrong : line;

  /// Elevation under selected segments in Sunrise; clean border in Twilight.
  List<BoxShadow> get segmentedActiveShadows => shadows.isEmpty
      ? const []
      : [
          BoxShadow(
            color: ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  /// Hairline safety border (`safety` at 30%).
  Color get dangerBorder => safety.withValues(alpha: 0.30);

  /// Switch off track.
  Color get switchOffTrack => isDark ? surface3 : surface2;

  /// Switch on track: active calm teal blended smoothly over `surface`.
  Color get switchOnTrack => tint(m1, switchOnTrackTint);

  /// Thumb color when switch is enabled.
  Color get switchThumbOn => pureWhiteConstant;

  /// Equalizer / slider thumb border color.
  Color get controlThumbBorder =>
      isDark ? pureWhiteConstant.withValues(alpha: 0.85) : pureWhiteConstant;

  /// Outer elevation under the floating nav pill (Sunrise only; hairline in Twilight).
  List<BoxShadow> get navPillShadows => shadows.isEmpty
      ? const []
      : [
          BoxShadow(
            color: ink.withValues(alpha: 0.14),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ];

  /// Center action ring shadow (Sunrise only).
  List<BoxShadow> get navCenterShadows => !isDark
      ? [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ]
      : const [];

  /// Active capsule fill behind the selected bottom-nav item.
  Color get navCapsuleFill => tint(primary, navActiveTint);

  /// Semantic foreground color for Fact / Guess / Story badges.
  Color labelColor(LabelType label) {
    return switch (label) {
      LabelType.fact => moodAnxious,
      LabelType.assumption => moodRestless,
      LabelType.interpretation => moodHeavy,
    };
  }

  /// Tinted badge fill derived from [labelColor].
  Color labelBackground(LabelType label) =>
      tint(labelColor(label), tintSelected);

  /// Hairline badge border derived from [labelColor].
  Color labelBorder(LabelType label) =>
      labelColor(label).withValues(alpha: 0.30);

  @override
  MindTokens copyWith({
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? lineStrong,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? primary,
    Color? onPrimary,
    Color? primaryDeep,
    Color? onMood,
    Color? safety,
    Color? safetySoft,
    double? glow,
    double? orbGlowFactor,
    List<BoxShadow>? shadows,
    Color? navGlass,
    Color? scrim,
    Color? focusRing,
    Color? m1,
    Color? m2,
    double? tintCard,
    double? tintSelected,
    double? tintBlob,
    double? dayBaseTint,
    double? dayStepTint,
    double? navActiveTint,
    double? switchOnTrackTint,
    double? cardRadius,
    double? tileRadius,
    double? rowRadius,
    double? buttonRadius,
    double? chipRadius,
    double? inputRadius,
    double? iconButtonRadius,
    double? sheetRadius,
    double? screenPadding,
    double? blockGap,
  }) {
    return MindTokens(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      onMood: onMood ?? this.onMood,
      safety: safety ?? this.safety,
      safetySoft: safetySoft ?? this.safetySoft,
      glow: glow ?? this.glow,
      orbGlowFactor: orbGlowFactor ?? this.orbGlowFactor,
      shadows: shadows ?? this.shadows,
      navGlass: navGlass ?? this.navGlass,
      scrim: scrim ?? this.scrim,
      focusRing: focusRing ?? this.focusRing,
      m1: m1 ?? this.m1,
      m2: m2 ?? this.m2,
      tintCard: tintCard ?? this.tintCard,
      tintSelected: tintSelected ?? this.tintSelected,
      tintBlob: tintBlob ?? this.tintBlob,
      dayBaseTint: dayBaseTint ?? this.dayBaseTint,
      dayStepTint: dayStepTint ?? this.dayStepTint,
      navActiveTint: navActiveTint ?? this.navActiveTint,
      switchOnTrackTint: switchOnTrackTint ?? this.switchOnTrackTint,
      cardRadius: cardRadius ?? this.cardRadius,
      tileRadius: tileRadius ?? this.tileRadius,
      rowRadius: rowRadius ?? this.rowRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      iconButtonRadius: iconButtonRadius ?? this.iconButtonRadius,
      sheetRadius: sheetRadius ?? this.sheetRadius,
      screenPadding: screenPadding ?? this.screenPadding,
      blockGap: blockGap ?? this.blockGap,
    );
  }

  @override
  MindTokens lerp(ThemeExtension<MindTokens>? other, double t) {
    if (other is! MindTokens) return this;
    return MindTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      onMood: Color.lerp(onMood, other.onMood, t)!,
      safety: Color.lerp(safety, other.safety, t)!,
      safetySoft: Color.lerp(safetySoft, other.safetySoft, t)!,
      glow: _lerpDouble(glow, other.glow, t),
      orbGlowFactor: _lerpDouble(orbGlowFactor, other.orbGlowFactor, t),
      shadows: BoxShadow.lerpList(shadows, other.shadows, t) ?? const [],
      navGlass: Color.lerp(navGlass, other.navGlass, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      m1: Color.lerp(m1, other.m1, t)!,
      m2: Color.lerp(m2, other.m2, t)!,
      tintCard: _lerpDouble(tintCard, other.tintCard, t),
      tintSelected: _lerpDouble(tintSelected, other.tintSelected, t),
      tintBlob: _lerpDouble(tintBlob, other.tintBlob, t),
      dayBaseTint: _lerpDouble(dayBaseTint, other.dayBaseTint, t),
      dayStepTint: _lerpDouble(dayStepTint, other.dayStepTint, t),
      navActiveTint: _lerpDouble(navActiveTint, other.navActiveTint, t),
      switchOnTrackTint: _lerpDouble(
        switchOnTrackTint,
        other.switchOnTrackTint,
        t,
      ),
      cardRadius: _lerpDouble(cardRadius, other.cardRadius, t),
      tileRadius: _lerpDouble(tileRadius, other.tileRadius, t),
      rowRadius: _lerpDouble(rowRadius, other.rowRadius, t),
      buttonRadius: _lerpDouble(buttonRadius, other.buttonRadius, t),
      chipRadius: _lerpDouble(chipRadius, other.chipRadius, t),
      inputRadius: _lerpDouble(inputRadius, other.inputRadius, t),
      iconButtonRadius: _lerpDouble(
        iconButtonRadius,
        other.iconButtonRadius,
        t,
      ),
      sheetRadius: _lerpDouble(sheetRadius, other.sheetRadius, t),
      screenPadding: _lerpDouble(screenPadding, other.screenPadding, t),
      blockGap: _lerpDouble(blockGap, other.blockGap, t),
    );
  }

  /// Boosts structural border visibility and secondary/tertiary ink contrast
  /// for older eyes, tired evenings, and high-glare environments while
  /// preserving Daylight and Vercel Obsidian Night ground/surface palettes.
  MindTokens withComfortBoost(bool enabled) {
    if (!enabled) return this;
    final isDark = brightness == Brightness.dark;
    return copyWith(
      line: isDark
          ? const Color.fromRGBO(255, 255, 255, 0.22)
          : const Color.fromRGBO(17, 17, 20, 0.20),
      lineStrong: isDark
          ? const Color.fromRGBO(255, 255, 255, 0.36)
          : const Color.fromRGBO(17, 17, 20, 0.34),
      ink2: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF3F3F46),
      ink3: isDark ? const Color(0xFFB4B4BD) : const Color(0xFF4B4B55),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Convenient BuildContext lookup for active [MindTokens].
extension MindTokensContext on BuildContext {
  MindTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<MindTokens>() ??
        MindTokens.forBrightness(theme.brightness);
  }
}
