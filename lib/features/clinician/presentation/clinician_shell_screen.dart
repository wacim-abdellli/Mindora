import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/config/app_edition.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/mind_formatters.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/display_comfort_controller.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_banner.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_dialog.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/mind_skeleton.dart';
import '../../../core/widgets/mind_switch.dart';
import '../../../core/widgets/mind_toast.dart';
import '../../clinic_sync/domain/clinic_account_models.dart';
import '../../profile/domain/clinical_condition_catalog.dart';
import '../../track/presentation/widgets/track_mood_utils.dart';
import '../controllers/clinician_providers.dart';
import '../data/clinician_auth_service.dart';
import '../domain/clinician_models.dart';
import 'clinician_patient_detail_screen.dart';
import 'widgets/clinician_record_editor_sheets.dart';
import 'widgets/create_patient_account_sheet.dart';
import 'widgets/import_patient_packet_sheet.dart';

enum _RosterFilter { all, shifts, unreviewed, pending, paused, demo }

enum _RosterSort { recent, priority, name }

/// Three-tab Psychiatrist & Clinician Workspace shell (`Patients`, `Overview`
/// Clinical Queue, `Practice`) with responsive tablet/desktop master-detail
/// split pane and explicit interaction-driven review state.
class ClinicianShellScreen extends ConsumerStatefulWidget {
  const ClinicianShellScreen({super.key});

  /// Viewport width threshold switching from phone bottom dock to tablet/desktop
  /// master-detail split workspace.
  static const double splitBreakpoint = 840.0;

  @override
  ConsumerState<ClinicianShellScreen> createState() =>
      _ClinicianShellScreenState();
}

class _ClinicianShellScreenState extends ConsumerState<ClinicianShellScreen> {
  int _tabIndex = 0;
  _RosterFilter _filter = _RosterFilter.all;
  _RosterSort _sort = _RosterSort.recent;
  String? _selectedPatientId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(workspaceRoleProvider.notifier)
            .setRole(AppWorkspaceRole.clinician);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _priorityScore(
    ClinicianPatientRecord r,
    ClinicPatientAccount? account,
    AppStrings strings,
  ) {
    var score = 0;
    if (r.hasSafetyPauseAlert) score += 1000;
    final shifts = r.divergences(strings).length;
    if (shifts > 0) score += 200 + shifts * 20;
    if (r.hasUnreviewedUpdate) score += 100;
    if (account?.status == ClinicAccountStatus.pendingFirstLogin) score += 40;
    if (account?.status == ClinicAccountStatus.paused) score -= 50;
    return score;
  }

  List<ClinicianPatientRecord> _filteredRoster(
    List<ClinicianPatientRecord> roster,
    Map<String, ClinicPatientAccount> accountsById,
    AppStrings strings,
  ) {
    final q = _searchQuery.trim().toLowerCase();
    final matched = roster.where((r) {
      final account = accountsById[r.patientId];
      final passesFilter = switch (_filter) {
        _RosterFilter.all => true,
        _RosterFilter.shifts =>
          r.hasSafetyPauseAlert || r.divergences(strings).isNotEmpty,
        _RosterFilter.unreviewed => r.hasUnreviewedUpdate,
        _RosterFilter.pending =>
          account?.status == ClinicAccountStatus.pendingFirstLogin,
        _RosterFilter.paused => account?.status == ClinicAccountStatus.paused,
        _RosterFilter.demo => r.isDemoCase,
      };
      if (!passesFilter) return false;
      if (q.isEmpty) return true;

      final nameMatch = r.displayName.toLowerCase().contains(q);
      final idMatch = r.patientId.toLowerCase().contains(q);
      final phoneMatch = (account?.loginIdentifier.toLowerCase().contains(q) ??
              false) ||
          r.clinicalRecord.phone.toLowerCase().contains(q) ||
          r.clinicalRecord.clinicFileNumber.toLowerCase().contains(q);
      final dxMatch = r.clinicalRecord.diagnoses.any(
        (d) =>
            d.label.toLowerCase().contains(q) ||
            d.code.toLowerCase().contains(q),
      );
      final trackMatch = (account?.assignedTrackIds ?? const <String>[]).any(
        (id) {
          for (final t in ClinicalTrack.values) {
            if (t.id == id &&
                t.localizedTitle(strings).toLowerCase().contains(q)) {
              return true;
            }
          }
          return id.toLowerCase().contains(q);
        },
      );
      final latestMood = r.latestTrace != null
          ? trackMoodLabel(r.latestTrace!.overallMood, strings).toLowerCase()
          : '';
      return nameMatch ||
          idMatch ||
          phoneMatch ||
          dxMatch ||
          trackMatch ||
          latestMood.contains(q);
    }).toList();

    switch (_sort) {
      case _RosterSort.recent:
        matched.sort((a, b) => b.lastSyncedAt.compareTo(a.lastSyncedAt));
      case _RosterSort.priority:
        matched.sort((a, b) {
          final sa = _priorityScore(a, accountsById[a.patientId], strings);
          final sb = _priorityScore(b, accountsById[b.patientId], strings);
          if (sb != sa) return sb.compareTo(sa);
          return b.lastSyncedAt.compareTo(a.lastSyncedAt);
        });
      case _RosterSort.name:
        matched.sort(
          (a, b) => a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase()),
        );
    }

    return matched;
  }

  String? _resolveSelectedPatientId(List<ClinicianPatientRecord> filtered) {
    if (filtered.isEmpty) return null;
    if (_selectedPatientId != null &&
        filtered.any((r) => r.patientId == _selectedPatientId)) {
      return _selectedPatientId;
    }
    return filtered.first.patientId;
  }

  void _openPatientDossier(
    BuildContext context,
    ClinicianPatientRecord record, {
    bool isWide = false,
  }) {
    HapticFeedback.lightImpact();
    // Explicit clinician click marks the chart as reviewed (never passive mount!).
    ref.read(clinicianRosterProvider.notifier).markReviewed(record.patientId);
    if (isWide) {
      setState(() {
        _selectedPatientId = record.patientId;
        _tabIndex = 0;
      });
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push('/clinician/patient/${record.patientId}');
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ClinicianPatientDetailScreen(patientId: record.patientId),
        ),
      );
    }
  }

  void _switchToPatientWorkspace(BuildContext context) {
    HapticFeedback.selectionClick();
    ref.read(workspaceRoleProvider.notifier).setRole(AppWorkspaceRole.patient);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('mf_preferred_workspace', 'patient');
      if (context.mounted) {
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          router.go(AppRouter.home);
        } else {
          Navigator.of(context).maybePop();
        }
      }
    });
  }

  String _relativeSyncLabel(DateTime dt, AppStrings strings) {
    return strings.formatRelativeTimeAgo(DateTime.now().difference(dt));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final rosterAsync = ref.watch(clinicianRosterProvider);
    final accountsById = ref.watch(clinicDoctorAccountsProvider).value ??
        const <String, ClinicPatientAccount>{};
    final profileAsync = ref.watch(clinicianProfileProvider);
    final demoEnabledAsync = ref.watch(clinicianDemoEnabledProvider);
    final appLock = ref.watch(appLockProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final roster = rosterAsync.value ?? const <ClinicianPatientRecord>[];
    final profile = profileAsync.value ?? const ClinicianProfile();
    final demoEnabled = demoEnabledAsync.value ?? true;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= ClinicianShellScreen.splitBreakpoint;
    final filtered = _filteredRoster(roster, accountsById, strings);
    final effectiveSelectedId = _resolveSelectedPatientId(filtered);

    if (isWide) {
      final listWidth = screenWidth >= 1160 ? 410.0 : 350.0;
      return Scaffold(
        backgroundColor: tokens.bg,
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              _buildNavigationRail(context, tokens, strings, reduceMotion),
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: listWidth,
                          child: _buildPatientsTab(
                            context: context,
                            tokens: tokens,
                            strings: strings,
                            roster: roster,
                            filtered: filtered,
                            accountsById: accountsById,
                            profile: profile,
                            demoEnabled: demoEnabled,
                            isLoading: rosterAsync.isLoading && roster.isEmpty,
                            isWide: true,
                            selectedPatientId: effectiveSelectedId,
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: tokens.line,
                        ),
                        Expanded(
                          child: effectiveSelectedId == null
                              ? Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 420,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: MindCard(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.folder_shared_outlined,
                                              size: 32,
                                              color: tokens.ink2,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              strings.noPatientsEmptyTitle,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: tokens.ink,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              strings.noPatientsEmptySub,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: tokens.ink2,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : ClinicianPatientDetailScreen(
                                  key: ValueKey<String>(effectiveSelectedId),
                                  patientId: effectiveSelectedId,
                                  embedded: true,
                                  // Prevent passive mount from silently wiping
                                  // unreviewed dots before the doctor clicks.
                                  autoMarkReviewed: false,
                                ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: _buildClinicalQueueTab(
                          context: context,
                          tokens: tokens,
                          strings: strings,
                          roster: roster,
                          accountsById: accountsById,
                          isWide: true,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: _buildPracticeTab(
                          context: context,
                          tokens: tokens,
                          strings: strings,
                          roster: roster,
                          accountsById: accountsById,
                          profile: profile,
                          demoEnabled: demoEnabled,
                          appLock: appLock,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _buildPatientsTab(
              context: context,
              tokens: tokens,
              strings: strings,
              roster: roster,
              filtered: filtered,
              accountsById: accountsById,
              profile: profile,
              demoEnabled: demoEnabled,
              isLoading: rosterAsync.isLoading && roster.isEmpty,
            ),
            _buildClinicalQueueTab(
              context: context,
              tokens: tokens,
              strings: strings,
              roster: roster,
              accountsById: accountsById,
            ),
            _buildPracticeTab(
              context: context,
              tokens: tokens,
              strings: strings,
              roster: roster,
              accountsById: accountsById,
              profile: profile,
              demoEnabled: demoEnabled,
              appLock: appLock,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingDock(tokens, strings, reduceMotion),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    MindTokens tokens,
    AppStrings strings,
    bool reduceMotion,
  ) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.15,
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: tokens.surface,
          border: BorderDirectional(
            end: BorderSide(color: tokens.line, width: 1.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tokens.cardTint,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                border: Border.all(color: tokens.line),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.medical_services_outlined,
                size: 20,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 20),
            _buildRailItem(
              index: 0,
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: strings.clinicianTabPatients,
              tokens: tokens,
              strings: strings,
              reduceMotion: reduceMotion,
            ),
            const SizedBox(height: 10),
            _buildRailItem(
              index: 1,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: strings.clinicianTabOverview,
              tokens: tokens,
              strings: strings,
              reduceMotion: reduceMotion,
            ),
            const SizedBox(height: 10),
            _buildRailItem(
              index: 2,
              icon: Icons.tune_outlined,
              activeIcon: Icons.tune_rounded,
              label: strings.clinicianTabPractice,
              tokens: tokens,
              strings: strings,
              reduceMotion: reduceMotion,
            ),
            const Spacer(),
            Tooltip(
              message: strings.switchLanguageTooltip,
              child: MindBadge(
                key: const ValueKey<String>('clinician-rail-lang-btn'),
                label: AppLanguage.fromCode(strings.languageCode).shortCode,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final next = switch (strings.languageCode) {
                    'en' => AppLanguage.french,
                    'fr' => AppLanguage.arabic,
                    _ => AppLanguage.english,
                  };
                  ref
                      .read(localeControllerProvider.notifier)
                      .setLanguage(next);
                },
              ),
            ),
            const SizedBox(height: 6),
            if (AppEditionConfig.isClinicianApp)
              IconButton(
                key: const ValueKey<String>('clinician-rail-lock-btn'),
                tooltip: strings.clinicianLockWorkspaceBtn,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.lock_outline_rounded, color: tokens.ink2),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ClinicianAuthService.lockSession();
                  GoRouter.maybeOf(context)?.go(AppRouter.clinicianAuth);
                },
              )
            else
              IconButton(
                tooltip: strings.switchToPatientWorkspaceBtn,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.swap_horiz_rounded, color: tokens.ink2),
                onPressed: () => _switchToPatientWorkspace(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRailItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required MindTokens tokens,
    required AppStrings strings,
    required bool reduceMotion,
  }) {
    final isSelected = _tabIndex == index;
    return MindPressable(
      semanticLabel: label,
      selected: isSelected,
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _tabIndex = index);
      },
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color:
                      isSelected ? tokens.navCapsuleFill : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? tokens.ink : tokens.ink3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: LabTheme.fontFamily,
                  fontFamilyFallback: LabTheme.fontFallback,
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? tokens.ink : tokens.ink3,
                  letterSpacing: strings.isArabic ? 0 : -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingDock(
    MindTokens tokens,
    AppStrings strings,
    bool reduceMotion,
  ) {
    return ColoredBox(
      color: tokens.bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
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
                        border: Border.all(color: tokens.line, width: 1.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          _buildDockItem(
                            index: 0,
                            icon: Icons.people_outline_rounded,
                            activeIcon: Icons.people_rounded,
                            label: strings.clinicianTabPatients,
                            tokens: tokens,
                            strings: strings,
                            reduceMotion: reduceMotion,
                          ),
                          _buildDockItem(
                            index: 1,
                            icon: Icons.dashboard_outlined,
                            activeIcon: Icons.dashboard_rounded,
                            label: strings.clinicianTabOverview,
                            tokens: tokens,
                            strings: strings,
                            reduceMotion: reduceMotion,
                          ),
                          _buildDockItem(
                            index: 2,
                            icon: Icons.tune_outlined,
                            activeIcon: Icons.tune_rounded,
                            label: strings.clinicianTabPractice,
                            tokens: tokens,
                            strings: strings,
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
    );
  }

  Widget _buildDockItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required MindTokens tokens,
    required AppStrings strings,
    required bool reduceMotion,
  }) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: MergeSemantics(
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _tabIndex = index);
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: SizedBox(
              height: 66,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      size: 20,
                      color: isSelected ? tokens.ink : tokens.ink3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: LabTheme.fontFamily,
                      fontFamilyFallback: LabTheme.fontFallback,
                      fontSize: 12.0,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? tokens.ink : tokens.ink3,
                      letterSpacing: strings.isArabic ? 0 : -0.1,
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

  // ---------------------------------------------------------------------------
  // TAB 0: PATIENTS TRIAGE ROSTER
  // ---------------------------------------------------------------------------
  Widget _buildPatientsTab({
    required BuildContext context,
    required MindTokens tokens,
    required AppStrings strings,
    required List<ClinicianPatientRecord> roster,
    required List<ClinicianPatientRecord> filtered,
    required Map<String, ClinicPatientAccount> accountsById,
    required ClinicianProfile profile,
    required bool demoEnabled,
    required bool isLoading,
    bool isWide = false,
    String? selectedPatientId,
  }) {
    final shiftsTotal = roster
        .where((r) => r.hasSafetyPauseAlert || r.divergences(strings).isNotEmpty)
        .length;
    final unreviewedTotal = roster.where((r) => r.hasUnreviewedUpdate).length;
    final pendingCount = roster
        .where(
          (r) =>
              accountsById[r.patientId]?.status ==
              ClinicAccountStatus.pendingFirstLogin,
        )
        .length;
    final pausedCount = roster
        .where(
          (r) =>
              accountsById[r.patientId]?.status == ClinicAccountStatus.paused,
        )
        .length;
    final hasActiveFilter =
        _searchQuery.trim().isNotEmpty || _filter != _RosterFilter.all;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        // Header Row
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.psychiatristWorkspaceTitle,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                      letterSpacing: strings.isArabic ? 0 : -0.4,
                    ),
                  ),
                ),
                if (AppEditionConfig.isClinicianApp) ...[
                  const SizedBox(width: 8),
                  MindBadge(label: strings.doctorEditionBadge),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${profile.displayName} · ${profile.clinicName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: tokens.ink2),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MindPressable(
                  key: const ValueKey<String>('clinician-add-patient-btn'),
                  semanticLabel: strings.createPatientAccountBtn,
                  onPressed: () => CreatePatientAccountSheet.show(context),
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.ink,
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 16,
                            color: tokens.bg,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              strings.createPatientAccountBtn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.bg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                MindPressable(
                  key: const ValueKey<String>('clinician-import-patient-btn'),
                  semanticLabel: strings.addOrImportPatientBtn,
                  onPressed: () => ImportPatientPacketSheet.show(context),
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 16,
                            color: tokens.ink,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              strings.addOrImportPatientBtn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Interactive KPI Summary Strip (tapping filters roster immediately)
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '${roster.length}',
                label: strings.kpiActivePatients,
                selected: _filter == _RosterFilter.all,
                onTap: () => setState(() => _filter = _RosterFilter.all),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '$shiftsTotal',
                label: strings.kpiBaselineShifts,
                highlight: shiftsTotal > 0,
                selected: _filter == _RosterFilter.shifts,
                onTap: () => setState(() => _filter = _RosterFilter.shifts),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '$unreviewedTotal',
                label: strings.kpiSharedUpdates,
                selected: _filter == _RosterFilter.unreviewed,
                onTap: () => setState(() => _filter = _RosterFilter.unreviewed),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Search Patients Field (name, phone, file #, diagnosis, track, mood)
        TextField(
          key: const ValueKey<String>('clinician-patient-search-field'),
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: TextStyle(fontSize: 14.0, color: tokens.ink),
          decoration: InputDecoration(
            isDense: true,
            hintText: strings.searchPatientsHint,
            hintStyle: TextStyle(fontSize: 13.5, color: tokens.ink3),
            filled: true,
            fillColor: tokens.surface,
            prefixIcon: Icon(Icons.search_rounded, size: 19, color: tokens.ink2),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: strings.clearFilterBtn,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(Icons.close_rounded, size: 18, color: tokens.ink2),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
              borderSide: BorderSide(color: tokens.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
              borderSide: BorderSide(color: tokens.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
              borderSide: BorderSide(color: tokens.ink, width: 1.2),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Filter Pills + Sort Controls
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            MindPill(
              label: strings.filterAll,
              isSelected: _filter == _RosterFilter.all,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => setState(() => _filter = _RosterFilter.all),
            ),
            MindPill(
              label: strings.filterShiftsNoted,
              isSelected: _filter == _RosterFilter.shifts,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => setState(() => _filter = _RosterFilter.shifts),
            ),
            MindPill(
              label: strings.filterNewUpdates,
              isSelected: _filter == _RosterFilter.unreviewed,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => setState(() => _filter = _RosterFilter.unreviewed),
            ),
            if (pendingCount > 0)
              MindPill(
                label: '${strings.filterPendingLogin} ($pendingCount)',
                isSelected: _filter == _RosterFilter.pending,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onTap: () => setState(() => _filter = _RosterFilter.pending),
              ),
            if (pausedCount > 0)
              MindPill(
                label: '${strings.filterPaused} ($pausedCount)',
                isSelected: _filter == _RosterFilter.paused,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onTap: () => setState(() => _filter = _RosterFilter.paused),
              ),
            if (demoEnabled)
              MindPill(
                label: strings.filterSampleShort,
                isSelected: _filter == _RosterFilter.demo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onTap: () => setState(() => _filter = _RosterFilter.demo),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Compact Sort Selector
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            MindBadge(
              key: const ValueKey<String>('roster-sort-recent'),
              icon: Icons.schedule_rounded,
              label: strings.sortRecentLabel,
              isSelected: _sort == _RosterSort.recent,
              onTap: () => setState(() => _sort = _RosterSort.recent),
            ),
            MindBadge(
              key: const ValueKey<String>('roster-sort-priority'),
              icon: Icons.priority_high_rounded,
              label: strings.sortPriorityLabel,
              isSelected: _sort == _RosterSort.priority,
              onTap: () => setState(() => _sort = _RosterSort.priority),
            ),
            MindBadge(
              key: const ValueKey<String>('roster-sort-name'),
              icon: Icons.sort_by_alpha_rounded,
              label: strings.sortNameLabel,
              isSelected: _sort == _RosterSort.name,
              onTap: () => setState(() => _sort = _RosterSort.name),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (isLoading)
          const Column(
            children: [
              MindSkeleton.card(height: 112),
              SizedBox(height: 10),
              MindSkeleton.card(height: 112),
            ],
          )
        else if (filtered.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  hasActiveFilter
                      ? Icons.search_off_rounded
                      : Icons.folder_shared_outlined,
                  size: 28,
                  color: tokens.ink2,
                ),
                const SizedBox(height: 10),
                Text(
                  hasActiveFilter
                      ? strings.noMatchingPatientsTitle
                      : strings.noPatientsEmptyTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasActiveFilter
                      ? strings.noMatchingPatientsSub
                      : strings.noPatientsEmptySub,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tokens.ink2,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                MindButton(
                  text: hasActiveFilter
                      ? strings.clearFilterBtn
                      : strings.createPatientAccountBtn,
                  variant: MindButtonVariant.soft,
                  isFullWidth: true,
                  onPressed: hasActiveFilter
                      ? () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _filter = _RosterFilter.all;
                          });
                        }
                      : () => CreatePatientAccountSheet.show(context),
                ),
              ],
            ),
          )
        else
          ...filtered.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPatientTriageCard(
                context,
                record,
                accountsById[record.patientId],
                tokens,
                strings,
                isWide: isWide,
                isSelected: isWide && record.patientId == selectedPatientId,
              ),
            ),
          ),
      ],
    );
  }

  Widget _kpiCard({
    required MindTokens tokens,
    required String value,
    required String label,
    bool highlight = false,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return MindCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      variant: (highlight || selected)
          ? MindCardVariant.tint
          : MindCardVariant.plain,
      borderColor: selected ? tokens.ink : (highlight ? tokens.safety : null),
      semanticLabel: '$label: $value',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: highlight ? tokens.safety : tokens.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.0,
              color: tokens.ink2,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTriageCard(
    BuildContext context,
    ClinicianPatientRecord record,
    ClinicPatientAccount? account,
    MindTokens tokens,
    AppStrings strings, {
    bool isWide = false,
    bool isSelected = false,
  }) {
    final latest = record.latestTrace;
    final hasLogs = record.latestPacket.traces.isNotEmpty;
    final recordedDays = record.baseline.totalRecordedDays;
    final recent = record.recentBaseline;
    final shifts = record.divergences(strings);
    final isPending = account?.status == ClinicAccountStatus.pendingFirstLogin;
    final isPaused = account?.status == ClinicAccountStatus.paused;
    final hasMood = !isPending && latest != null && latest.hasExplicitMood;
    final moodKey = hasMood ? latest.overallMood : '';
    final moodOption = hasMood ? trackMoodOptionFor(moodKey) : null;
    final agenda = record.latestPacket.preVisitAgenda;
    final activeDx = record.activeDiagnoses;
    final sleepStr = recent.averageSleepHours != null
        ? MindFormatters.hours(recent.averageSleepHours!, strings)
        : '--';

    final statusLine = isPaused
        ? strings.accountPausedBadge
        : (!hasLogs
            ? strings.connectedNoCheckInsLabel
            : '${hasMood ? trackMoodLabel(moodKey, strings) : '--'} · '
                '${hasMood ? '${latest.moodIntensity}/10' : '--'} · '
                '${_relativeSyncLabel(record.lastSyncedAt, strings)}');

    return MindCard(
      padding: const EdgeInsets.all(16),
      variant: isSelected ? MindCardVariant.tint : MindCardVariant.plain,
      borderColor: isSelected
          ? tokens.accentInk
          : (record.hasSafetyPauseAlert ? tokens.safety : null),
      semanticLabel: '${record.displayName}, $statusLine',
      onTap: () => _openPatientDossier(context, record, isWide: isWide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPaused)
                Icon(Icons.pause_circle_outline_rounded,
                    size: 16, color: tokens.safety)
              else if (isPending || !hasLogs)
                Icon(Icons.schedule_rounded, size: 15, color: tokens.ink3)
              else if (moodOption != null)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: moodOption.color,
                  ),
                )
              else
                Icon(Icons.circle_outlined, size: 14, color: tokens.ink3),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  record.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              if (record.isDemoCase) ...[
                MindBadge(label: strings.demoDatasetBadge),
                const SizedBox(width: 6),
              ],
              if (record.hasUnreviewedUpdate)
                Semantics(
                  label: strings.filterNewUpdates,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.accentInk,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: tokens.ink3,
              ),
            ],
          ),
          if (activeDx.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              activeDx
                  .take(2)
                  .map(
                    (d) =>
                        '${d.displayTitle} (${d.certainty.localizedLabel(strings)})',
                  )
                  .join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.accentInk,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            statusLine,
            style: TextStyle(
              fontSize: 12.5,
              color: tokens.ink2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (!isPending && hasLogs) ...[
            const SizedBox(height: 10),
            _SevenDaySleepMoodStrip(
              record: record,
              sleepStr: sleepStr,
              strings: strings,
              tokens: tokens,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (record.hasSafetyPauseAlert)
                MindBadge(
                  icon: Icons.warning_amber_rounded,
                  label: strings.safetyPauseAlertBadge,
                  backgroundColor: tokens.safetySoft,
                  borderColor: tokens.safety,
                  textColor: tokens.safety,
                ),
              if (isPaused)
                MindBadge(
                  icon: Icons.pause_circle_outline_rounded,
                  label: strings.accountPausedBadge,
                  backgroundColor: tokens.safetySoft,
                  textColor: tokens.safety,
                )
              else if (isPending || !hasLogs)
                MindBadge(
                  icon: Icons.schedule_rounded,
                  label: isPending
                      ? strings.awaitingFirstLoginBadge
                      : strings.connectedNoCheckInsLabel,
                  borderColor: tokens.line,
                  textColor: tokens.ink2,
                )
              else if (shifts.isNotEmpty)
                MindBadge(
                  icon: Icons.trending_up_rounded,
                  label: strings.shiftsCountBadge(shifts.length),
                  borderColor: tokens.safety,
                  textColor: tokens.safety,
                )
              else if (recordedDays < 7)
                MindBadge(
                  icon: Icons.hourglass_bottom_rounded,
                  label: strings.buildingBaselineBadge(recordedDays),
                  borderColor: tokens.line,
                  textColor: tokens.ink2,
                )
              else
                MindBadge(
                  icon: Icons.check_circle_outline_rounded,
                  label: strings.baselineSteadyBadge,
                  borderColor: tokens.line,
                  textColor: tokens.ink2,
                ),
              if (!isPending &&
                  hasLogs &&
                  recent.averageSleepHours != null &&
                  recent.averageSleepHours! < 5.5)
                MindBadge(
                  icon: Icons.bedtime_outlined,
                  label: strings.lowSleepFlagBadge,
                  borderColor: tokens.safety,
                  textColor: tokens.safety,
                ),
            ],
          ),
          if (agenda != null &&
              !agenda.isEmpty &&
              record.latestPacket.consentScope.includePreVisitAgenda) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                border: Border.all(color: tokens.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.event_note_outlined, size: 14, color: tokens.ink2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      agenda.selectedTopics.isNotEmpty
                          ? agenda.selectedTopics.join(' · ')
                          : agenda.patientQuestion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.ink2,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DAILY CLINICAL QUEUE DASHBOARD (NO MEANINGLESS COHORT AVERAGES)
  // ---------------------------------------------------------------------------
  Widget _buildClinicalQueueTab({
    required BuildContext context,
    required MindTokens tokens,
    required AppStrings strings,
    required List<ClinicianPatientRecord> roster,
    required Map<String, ClinicPatientAccount> accountsById,
    bool isWide = false,
  }) {
    // Keep real clinic KPIs clean from demo records once real patients exist.
    final realPatients = roster.where((r) => !r.isDemoCase).toList();
    final showingDemoOnly = realPatients.isEmpty && roster.isNotEmpty;
    final queueSource = showingDemoOnly ? roster : realPatients;

    final safetyQueue = queueSource
        .where((r) => r.hasSafetyPauseAlert)
        .toList(growable: false);
    final shiftPairs = <(ClinicianPatientRecord, String, String)>[];
    for (final record in queueSource) {
      for (final div in record.divergences(strings)) {
        shiftPairs.add((record, div.title, div.baselineComparison));
      }
    }
    final unreviewedQueue = queueSource
        .where((r) => r.hasUnreviewedUpdate)
        .toList(growable: false);
    final followUpQueue = queueSource
        .where((r) => r.clinicalRecord.nextAppointmentAt != null)
        .toList()
      ..sort(
        (a, b) => a.clinicalRecord.nextAppointmentAt!
            .compareTo(b.clinicalRecord.nextAppointmentAt!),
      );
    final pendingAccounts = queueSource
        .where(
          (r) =>
              accountsById[r.patientId]?.status ==
              ClinicAccountStatus.pendingFirstLogin,
        )
        .toList(growable: false);

    final now = DateTime.now();
    final inactiveQueue = <(ClinicianPatientRecord, int)>[];
    for (final r in queueSource) {
      if (accountsById[r.patientId]?.status ==
          ClinicAccountStatus.pendingFirstLogin) {
        continue;
      }
      final latest = r.latestTrace;
      if (latest != null) {
        final daysAgo = now.difference(latest.date).inDays;
        if (daysAgo > 7) {
          inactiveQueue.add((r, daysAgo));
        }
      }
    }

    return ListView(
      key: const ValueKey<String>('clinician-queue-dashboard'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Text(
          strings.clinicalQueueTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        if (showingDemoOnly) ...[
          const SizedBox(height: 8),
          MindBanner(body: strings.demoBannerNotice, tone: MindBannerTone.info),
        ],
        const SizedBox(height: 14),

        // 4 Actionable Clinical Queue Counters
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '${safetyQueue.length}',
                label: strings.kpiSafetyAlerts,
                highlight: safetyQueue.isNotEmpty,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '${shiftPairs.length}',
                label: strings.kpiBaselineShifts,
                highlight: shiftPairs.isNotEmpty,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '${unreviewedQueue.length}',
                label: strings.kpiSharedUpdates,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '${pendingAccounts.length + followUpQueue.length}',
                label: strings.kpiPendingFollowUps,
              ),
            ),
          ],
        ),

        // Section 1: Safety Pauses (Highest Priority)
        if (safetyQueue.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            strings.queueNeedsAttentionTitle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tokens.safety,
            ),
          ),
          const SizedBox(height: 8),
          ...safetyQueue.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                borderColor: tokens.safety,
                padding: const EdgeInsets.all(14),
                onTap: () =>
                    _openPatientDossier(context, record, isWide: isWide),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: tokens.safety,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.displayName,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.safetyPauseAlertBadge,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.safety,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: tokens.ink3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Section 2: Notable Baseline Shifts
        const SizedBox(height: 18),
        Text(
          strings.cohortObservationsTitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        if (shiftPairs.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              strings.queueAllClearLabel,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...shiftPairs.map((item) {
            final record = item.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                padding: const EdgeInsets.all(14),
                onTap: () =>
                    _openPatientDossier(context, record, isWide: isWide),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${record.displayName} · ${item.$2}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: tokens.ink3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.ink2,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        // Section 3: Upcoming Follow-Ups
        if (followUpQueue.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            strings.queueUpcomingFollowUpsTitle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 8),
          ...followUpQueue.map((record) {
            final appt = record.clinicalRecord.nextAppointmentAt!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MindCard(
                padding: const EdgeInsets.all(14),
                onTap: () =>
                    _openPatientDossier(context, record, isWide: isWide),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: tokens.accentInk,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        record.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    MindBadge(
                      label: MindFormatters.shortDate(appt, strings),
                      backgroundColor: tokens.primarySoft,
                      textColor: tokens.ink,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // Section 4: Onboarding & Engagement Watch
        if (pendingAccounts.isNotEmpty || inactiveQueue.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            strings.queueOnboardingWatchTitle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 8),
          ...pendingAccounts.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MindCard(
                padding: const EdgeInsets.all(14),
                onTap: () =>
                    _openPatientDossier(context, record, isWide: isWide),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 18, color: tokens.ink2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          Text(
                            strings.awaitingFirstLoginBadge,
                            style: TextStyle(fontSize: 12, color: tokens.ink2),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: tokens.ink3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...inactiveQueue.map(
            (pair) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MindCard(
                padding: const EdgeInsets.all(14),
                onTap: () =>
                    _openPatientDossier(context, pair.$1, isWide: isWide),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 18,
                      color: tokens.ink2,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pair.$1.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    MindBadge(label: strings.inactiveDaysBadge(pair.$2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: PRACTICE, GOVERNANCE & PRIVACY SETTINGS
  // ---------------------------------------------------------------------------
  Widget _buildPracticeTab({
    required BuildContext context,
    required MindTokens tokens,
    required AppStrings strings,
    required List<ClinicianPatientRecord> roster,
    required Map<String, ClinicPatientAccount> accountsById,
    required ClinicianProfile profile,
    required bool demoEnabled,
    required AppLockState appLock,
  }) {
    final managedCount = accountsById.length;
    final offlineImportedCount = roster
        .where((r) => !r.isDemoCase && !accountsById.containsKey(r.patientId))
        .length;

    final profileMeta = <String>[
      profile.specialty,
      profile.clinicName,
      if (profile.licenseRef.trim().isNotEmpty) profile.licenseRef.trim(),
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Text(
          strings.clinicianTabPractice,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          strings.practiceProfileTitle,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: strings.isArabic ? 0 : 0.6,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        MindCard(
          key: const ValueKey<String>('clinician-practice-profile-card'),
          padding: const EdgeInsets.all(16),
          onTap: () => _editProfileSheet(context, profile),
          child: Row(
            children: [
              Icon(Icons.medical_services_outlined, size: 22, color: tokens.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profileMeta,
                      style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                    ),
                    if (profile.clinicPhone.trim().isNotEmpty ||
                        profile.clinicAddress.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (profile.clinicPhone.trim().isNotEmpty)
                            MindFormatters.ltrIsolate(
                              profile.clinicPhone.trim(),
                            ),
                          if (profile.clinicAddress.trim().isNotEmpty)
                            profile.clinicAddress.trim(),
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: tokens.ink3),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: tokens.ink2),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Builder(
          builder: (ctx) {
            final currentLocale = ref.watch(localeControllerProvider);
            final currentTheme = ref.watch(themeControllerProvider);
            final comfortMode = ref.watch(displayComfortProvider);
            final langIndex = switch (currentLocale.languageCode) {
              'fr' => 1,
              'ar' => 2,
              _ => 0,
            };
            final themeIndex = currentTheme == ThemeMode.light
                ? 0
                : (currentTheme == ThemeMode.dark ? 1 : 2);
            return MindCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.workspacePreferencesSection,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.languageTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MindSegmented(
                    key: const ValueKey<String>('clinician-language-segmented'),
                    index: langIndex,
                    labels: const ['English', 'Français', 'العربية'],
                    onChanged: (idx) {
                      HapticFeedback.selectionClick();
                      final lang = switch (idx) {
                        1 => AppLanguage.french,
                        2 => AppLanguage.arabic,
                        _ => AppLanguage.english,
                      };
                      ref
                          .read(localeControllerProvider.notifier)
                          .setLanguage(lang);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.themeModeTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MindSegmented(
                    key: const ValueKey<String>('clinician-theme-segmented'),
                    index: themeIndex,
                    labels: [
                      strings.themeSunriseLabel,
                      strings.themeNightLabel,
                      strings.themeAutoLabel,
                    ],
                    onChanged: (idx) {
                      HapticFeedback.selectionClick();
                      final mode = idx == 0
                          ? ThemeMode.light
                          : (idx == 1 ? ThemeMode.dark : ThemeMode.system);
                      ref.read(themeControllerProvider.notifier).setTheme(mode);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.comfortModeTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.comfortModeSub,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MindSwitch(
                        key: const ValueKey<String>('clinician-comfort-switch'),
                        value: comfortMode,
                        semanticLabel: strings.comfortModeTitle,
                        onChanged: (val) => ref
                            .read(displayComfortProvider.notifier)
                            .setComfortMode(val),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 14),
        MindCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.demoCohortToggleTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.demoCohortToggleSub,
                            style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MindSwitch(
                      key: const ValueKey<String>(
                        'clinician-demo-cohort-switch',
                      ),
                      value: demoEnabled,
                      semanticLabel: strings.demoCohortToggleTitle,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(clinicianDemoEnabledProvider.notifier)
                            .setEnabled(v);
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.line),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.clinicBiometricLockTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.biometricLockSub,
                            style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MindSwitch(
                      value: appLock.isEnabled,
                      semanticLabel: strings.clinicBiometricLockTitle,
                      onChanged: (v) async {
                        await ref
                            .read(appLockProvider.notifier)
                            .toggleBiometrics(v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        // Governance & Data Controls (Audit Log + Honest Offline Import Count)
        MindCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _practiceActionRow(
                key: const ValueKey<String>('clinician-audit-log-btn'),
                tokens: tokens,
                icon: Icons.history_rounded,
                title: strings.clinicAuditLogTitle,
                subtitle:
                    '${strings.managedPatientsCountLabel}: $managedCount',
                onTap: () => ClinicAuditLogSheet.show(context),
              ),
              Divider(height: 1, color: tokens.line),
              _practiceActionRow(
                tokens: tokens,
                icon: Icons.download_outlined,
                title: strings.importPacketTitle,
                onTap: () => ImportPatientPacketSheet.show(context),
              ),
              Divider(height: 1, color: tokens.line),
              _practiceActionRow(
                key: const ValueKey<String>('clinician-clear-offline-btn'),
                tokens: tokens,
                icon: Icons.delete_outline_rounded,
                title:
                    '${strings.clearOfflineImportsTitle} ($offlineImportedCount)',
                enabled: offlineImportedCount > 0,
                onTap: () => _confirmClearImported(context, strings),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        MindCard(
          variant: MindCardVariant.flat,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 18, color: tokens.ink2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.clinicalBoundaryNote,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tokens.ink2,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (AppEditionConfig.isClinicianApp) ...[
          const SizedBox(height: 18),
          MindButton(
            key: const ValueKey<String>('clinician-practice-lock-btn'),
            text: strings.clinicianLockWorkspaceBtn,
            variant: MindButtonVariant.secondary,
            leadingIcon: Icons.lock_outline_rounded,
            isFullWidth: true,
            onPressed: () {
              HapticFeedback.selectionClick();
              ClinicianAuthService.lockSession();
              GoRouter.maybeOf(context)?.go(AppRouter.clinicianAuth);
            },
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 10),
            MindButton(
              key: const ValueKey<String>('clinician-preview-patient-demo-btn'),
              text: strings.previewAsPatientDemoBtn,
              variant: MindButtonVariant.soft,
              leadingIcon: Icons.visibility_outlined,
              isFullWidth: true,
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('mf_clinician_demo_preview', true);
                if (context.mounted) {
                  GoRouter.maybeOf(context)?.go(AppRouter.home);
                }
              },
            ),
          ],
        ] else ...[
          const SizedBox(height: 18),
          MindButton(
            text: strings.switchToPatientWorkspaceBtn,
            variant: MindButtonVariant.primary,
            leadingIcon: Icons.person_outline_rounded,
            isFullWidth: true,
            onPressed: () => _switchToPatientWorkspace(context),
          ),
        ],
      ],
    );
  }

  Widget _practiceActionRow({
    Key? key,
    required MindTokens tokens,
    required IconData icon,
    required String title,
    String? subtitle,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    final fg = enabled ? tokens.ink : tokens.ink3;
    return MindPressable(
      key: key,
      semanticLabel: title,
      enabled: enabled,
      onPressed: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: tokens.ink2),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: enabled ? tokens.ink3 : tokens.lineStrong,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfileSheet(
    BuildContext context,
    ClinicianProfile profile,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditClinicianProfileSheet(profile: profile),
    );
  }

  Future<void> _confirmClearImported(
    BuildContext context,
    AppStrings strings,
  ) async {
    final confirmed = await showMindConfirmDialog(
      context,
      title: strings.clearOfflineImportsTitle,
      body: strings.clearImportedPatientsConfirm,
      confirmLabel: strings.clearImportedPatientsBtn,
      cancelLabel: strings.cancelBtn,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed && mounted) {
      await ref.read(clinicianRosterProvider.notifier).clearImportedPatients();
    }
  }
}

class _EditClinicianProfileSheet extends ConsumerStatefulWidget {
  const _EditClinicianProfileSheet({required this.profile});

  final ClinicianProfile profile;

  @override
  ConsumerState<_EditClinicianProfileSheet> createState() =>
      _EditClinicianProfileSheetState();
}

class _EditClinicianProfileSheetState
    extends ConsumerState<_EditClinicianProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _clinicCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
    _specCtrl = TextEditingController(text: widget.profile.specialty);
    _clinicCtrl = TextEditingController(text: widget.profile.clinicName);
    _licenseCtrl = TextEditingController(text: widget.profile.licenseRef);
    _phoneCtrl = TextEditingController(text: widget.profile.clinicPhone);
    _addressCtrl = TextEditingController(text: widget.profile.clinicAddress);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _clinicCtrl.dispose();
    _licenseCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    final sheet = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        maxWidth: isWide ? 560 : double.infinity,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.sheetRadius),
        ),
        border: Border(
          top: BorderSide(color: tokens.line),
          left: isWide ? BorderSide(color: tokens.line) : BorderSide.none,
          right: isWide ? BorderSide(color: tokens.line) : BorderSide.none,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.editPracticeProfileTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: InputDecoration(
                    labelText: strings.clinicianNameLabel,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _specCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: InputDecoration(
                    labelText: strings.clinicianSpecialtyLabel,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _clinicCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: InputDecoration(
                    labelText: strings.clinicNameLabel,
                  ),
                ),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    key: const ValueKey<String>('practice-license-ref-field'),
                    controller: _licenseCtrl,
                    style: TextStyle(fontSize: 14, color: tokens.ink),
                    decoration: InputDecoration(
                      labelText: strings.clinicianLicenseRefField,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 14, color: tokens.ink),
                    decoration: InputDecoration(
                      labelText: strings.clinicPhoneField,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressCtrl,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: InputDecoration(
                    labelText: strings.clinicAddressField,
                  ),
                ),
                const SizedBox(height: 16),
                MindButton(
                  key: const ValueKey<String>('practice-profile-save-btn'),
                  text: strings.saveChangesBtn,
                  isFullWidth: true,
                  isLoading: _isSaving,
                  onPressed: () async {
                    setState(() => _isSaving = true);
                    final navigator = Navigator.of(context);
                    try {
                      await ref
                          .read(clinicianProfileProvider.notifier)
                          .updateProfile(
                            widget.profile.copyWith(
                              displayName: _nameCtrl.text.trim().isEmpty
                                  ? widget.profile.displayName
                                  : _nameCtrl.text.trim(),
                              specialty: _specCtrl.text.trim().isEmpty
                                  ? widget.profile.specialty
                                  : _specCtrl.text.trim(),
                              clinicName: _clinicCtrl.text.trim().isEmpty
                                  ? widget.profile.clinicName
                                  : _clinicCtrl.text.trim(),
                              licenseRef: _licenseCtrl.text.trim(),
                              clinicPhone: _phoneCtrl.text.trim(),
                              clinicAddress: _addressCtrl.text.trim(),
                            ),
                          );
                      if (mounted) {
                        final rootCtx = navigator.context;
                        navigator.pop();
                        if (rootCtx.mounted) {
                          showMindToast(
                            rootCtx,
                            strings.practiceProfileSavedToast,
                            variant: MindToastVariant.success,
                          );
                        }
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return isWide ? Center(heightFactor: 1.0, child: sheet) : sheet;
  }
}

class _SevenDaySleepMoodStrip extends StatelessWidget {
  const _SevenDaySleepMoodStrip({
    required this.record,
    required this.sleepStr,
    required this.strings,
    required this.tokens,
  });

  final ClinicianPatientRecord record;
  final String sleepStr;
  final AppStrings strings;
  final MindTokens tokens;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = <String, ({String mood, double? sleep})>{};
    for (final t in record.latestPacket.traces) {
      byDay[t.dateKey] = (mood: t.overallMood, sleep: t.sleepHours);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.line),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (idx) {
                  final day = today.subtract(Duration(days: 6 - idx));
                  final key =
                      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final item = byDay[key];
                  final barColor = item != null
                      ? MindTokens.moodColorByKey(item.mood)
                      : tokens.lineStrong;
                  final barHeight = item == null
                      ? 4.0
                      : (item.sleep != null
                            ? (item.sleep! * 2.1).clamp(7.0, 20.0)
                            : 10.0);
                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 22,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 6,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: item != null
                                    ? barColor
                                    : tokens.line.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.weekdayInitial(day.weekday),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: tokens.ink3,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                border: Border.all(color: tokens.line),
              ),
              child: Text(
                strings.sleep7dShortLabel(sleepStr),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
