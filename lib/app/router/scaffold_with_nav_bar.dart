import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
import '../theme/lab_theme.dart';
import '../theme/mind_tokens.dart';

/// Floating frosted-glass bottom navigation dock matching Vercel Dark luxury aesthetics:
/// - Floating balanced dock (height `66`, radius `28`, `navGlass` + blur `24`, `1px line`)
/// - 5 harmonized items (`Home`, `Track`, `AI Guide`, `Insights`, `Profile`)
/// - Zero double-highlight confusion: only the active tab illuminates
/// - Active standard tab: sleek 44x28 micro-capsule in `tokens.navCapsuleFill` with `tokens.ink` icon
/// - Active AI Guide tab: luminous gradient capsule in `[tokens.m2, tokens.m1]` with soft glow
/// - Inactive AI Guide tab: elegant clinical jewel capsule with `tokens.cardTint` and hairline border
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final currentIndex = navigationShell.currentIndex;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: navigationShell,
      bottomNavigationBar: ColoredBox(
        color: tokens.bg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
              child: RepaintBoundary(
                child: Container(
                  height: 66,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: tokens.navPillShadows,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tokens.navGlass,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: tokens.line,
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            _buildNavItem(
                              index: 0,
                              currentIndex: currentIndex,
                              icon: Icons.home_outlined,
                              activeIcon: Icons.home_rounded,
                              label: strings.navHome,
                              tokens: tokens,
                              reduceMotion: reduceMotion,
                            ),
                            _buildNavItem(
                              index: 1,
                              currentIndex: currentIndex,
                              icon: Icons.adjust_outlined,
                              activeIcon: Icons.adjust_rounded,
                              label: strings.navTrack,
                              tokens: tokens,
                              reduceMotion: reduceMotion,
                            ),
                            _buildCenterAiItem(
                              index: 2,
                              currentIndex: currentIndex,
                              icon: Icons.psychology_alt_outlined,
                              activeIcon: Icons.psychology_alt_rounded,
                              label: strings.navAiGuide,
                              tokens: tokens,
                              reduceMotion: reduceMotion,
                            ),
                            _buildNavItem(
                              index: 3,
                              currentIndex: currentIndex,
                              icon: Icons.auto_stories_outlined,
                              activeIcon: Icons.auto_stories_rounded,
                              label: strings.navInsights,
                              tokens: tokens,
                              reduceMotion: reduceMotion,
                            ),
                            _buildNavItem(
                              index: 4,
                              currentIndex: currentIndex,
                              icon: Icons.person_outline_rounded,
                              activeIcon: Icons.person_rounded,
                              label: strings.navProfile,
                              tokens: tokens,
                              reduceMotion: reduceMotion,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required MindTokens tokens,
    required bool reduceMotion,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: MergeSemantics(
          child: InkWell(
            onTap: () => _onTap(index),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: SizedBox(
              height: 66,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 44 : 36,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.navCapsuleFill
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      scale: isSelected && !reduceMotion ? 1.06 : 1.0,
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        isSelected ? activeIcon : icon,
                        size: 20,
                        color: isSelected ? tokens.ink : tokens.ink3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontFamily: LabTheme.fontFamily,
                      fontFamilyFallback: LabTheme.fontFallback,
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? tokens.ink : tokens.ink3,
                      letterSpacing: -0.2,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAiItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required MindTokens tokens,
    required bool reduceMotion,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: MergeSemantics(
          child: InkWell(
            onTap: () => _onTap(index),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: SizedBox(
              height: 66,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 48 : 36,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [tokens.m2, tokens.m1],
                            )
                          : null,
                      color: isSelected ? null : tokens.cardTint,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: tokens.line,
                              width: 1.0,
                            ),
                      boxShadow: isSelected ? tokens.navCenterShadows : null,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      scale: isSelected && !reduceMotion ? 1.06 : 1.0,
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        isSelected ? activeIcon : icon,
                        size: 20,
                        color: isSelected ? tokens.onMood : tokens.ink2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontFamily: LabTheme.fontFamily,
                      fontFamilyFallback: LabTheme.fontFallback,
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? tokens.ink : tokens.ink3,
                      letterSpacing: -0.2,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
