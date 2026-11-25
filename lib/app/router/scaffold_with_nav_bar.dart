import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
import '../theme/lab_theme.dart';
import '../theme/mind_tokens.dart';

/// Floating 5-tab single-job navigation dock (`Today`, `My days`, `Talk`,
/// `Patterns`, `Me`) built for both older adults (`>= 56dp` tall hits,
/// always-visible `>= 12sp` labels) and Gen Z (warm Sunrise/Twilight frosted
/// glass + smooth spring indicator).
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

    final tabs = [
      (
        icon: Icons.wb_sunny_outlined,
        activeIcon: Icons.wb_sunny_rounded,
        label: strings.navToday,
      ),
      (
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: strings.navMyDays,
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: strings.navTalk,
      ),
      (
        icon: Icons.auto_graph_rounded,
        activeIcon: Icons.insights_rounded,
        label: strings.navPatterns,
      ),
      (
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: strings.navMe,
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.bg,
      body: navigationShell,
      bottomNavigationBar: ColoredBox(
        color: tokens.bg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.90,
              maxScaleFactor: 1.25,
              child: RepaintBoundary(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 70),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: tokens.navPillShadows,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tokens.navGlass,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: tokens.line,
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < tabs.length; i++)
                              _buildNavItem(
                                index: i,
                                currentIndex: currentIndex,
                                icon: tabs[i].icon,
                                activeIcon: tabs[i].activeIcon,
                                label: tabs[i].label,
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
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 46 : 36,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.navCapsuleFill
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      scale: isSelected && !reduceMotion ? 1.08 : 1.0,
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        isSelected ? activeIcon : icon,
                        size: 21,
                        color: isSelected ? tokens.primary : tokens.ink2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontFamily: LabTheme.fontFamily,
                      fontFamilyFallback: LabTheme.fontFallback,
                      fontSize: 12.0,
                      height: 1.15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? tokens.primary : tokens.ink2,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                      ),
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
