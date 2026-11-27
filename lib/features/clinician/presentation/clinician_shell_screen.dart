import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/config/app_edition.dart';
import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_switch.dart';
import '../../mind_trace/domain/affect_taxonomy.dart';
import '../../track/presentation/widgets/track_mood_utils.dart';
import '../controllers/clinician_providers.dart';
import '../domain/clinician_models.dart';
import 'clinician_patient_detail_screen.dart';
import 'widgets/import_patient_packet_sheet.dart';

enum _RosterFilter { all, shifts, unreviewed, demo }

/// Three-tab Psychiatrist & Clinician Workspace shell (`Patients`, `Overview`,
/// `Practice`) paired with the luxury floating frosted-glass navigation dock.
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
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('mf_preferred_workspace', 'clinician');
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClinicianPatientRecord> _filteredRoster(
    List<ClinicianPatientRecord> roster,
    AppStrings strings,
  ) {
    final q = _searchQuery.trim().toLowerCase();
    return roster.where((r) {
      final passesFilter = switch (_filter) {
        _RosterFilter.all => true,
        _RosterFilter.shifts => r.divergences(strings).isNotEmpty,
        _RosterFilter.unreviewed => r.hasUnreviewedUpdate,
        _RosterFilter.demo => r.isDemoCase,
      };
      if (!passesFilter) return false;
      if (q.isEmpty) return true;
      final nameMatch = r.displayName.toLowerCase().contains(q);
      final idMatch = r.patientId.toLowerCase().contains(q);
      final latestMood = r.latestTrace != null
          ? trackMoodLabel(r.latestTrace!.overallMood, strings).toLowerCase()
          : '';
      return nameMatch || idMatch || latestMood.contains(q);
    }).toList(growable: false);
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
    final profileAsync = ref.watch(clinicianProfileProvider);
    final demoEnabledAsync = ref.watch(clinicianDemoEnabledProvider);
    final appLock = ref.watch(appLockProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final roster = rosterAsync.value ?? const <ClinicianPatientRecord>[];
    final profile = profileAsync.value ?? const ClinicianProfile();
    final demoEnabled = demoEnabledAsync.value ?? true;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= ClinicianShellScreen.splitBreakpoint;
    final filtered = _filteredRoster(roster, strings);
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
                            profile: profile,
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
                                ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: _buildCohortOverviewTab(
                          context: context,
                          tokens: tokens,
                          strings: strings,
                          roster: roster,
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
              profile: profile,
              isLoading: rosterAsync.isLoading && roster.isEmpty,
            ),
            _buildCohortOverviewTab(
              context: context,
              tokens: tokens,
              strings: strings,
              roster: roster,
            ),
            _buildPracticeTab(
              context: context,
              tokens: tokens,
              strings: strings,
              roster: roster,
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
              icon: Icons.insights_outlined,
              activeIcon: Icons.insights_rounded,
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
            if (!AppEditionConfig.isClinicianApp)
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: MindPressable(
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
                            icon: Icons.insights_outlined,
                            activeIcon: Icons.insights_rounded,
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
    required ClinicianProfile profile,
    required bool isLoading,
    bool isWide = false,
    String? selectedPatientId,
  }) {
    final shiftsTotal = roster
        .where((r) => r.divergences(strings).isNotEmpty)
        .length;
    final unreviewedTotal =
        roster.where((r) => r.hasUnreviewedUpdate).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        // Header Row (Wraps cleanly on 320px viewports)
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
              style: TextStyle(
                fontSize: 12.5,
                color: tokens.ink2,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Semantics(
                  button: true,
                  label: strings.addOrImportPatientBtn,
                  child: MindPressable(
                    key: const ValueKey<String>('clinician-import-patient-btn'),
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
                          color: tokens.ink,
                          borderRadius:
                              BorderRadius.circular(tokens.chipRadius),
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
                                strings.addOrImportPatientBtn,
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
                ),
                Semantics(
                  button: true,
                  label: strings.invitePatientBtn,
                  child: MindPressable(
                    key: const ValueKey<String>('clinician-invite-patient-btn'),
                    onPressed: () =>
                        _copyClinicInvite(context, profile, tokens, strings),
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
                          borderRadius:
                              BorderRadius.circular(tokens.chipRadius),
                          border: Border.all(color: tokens.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 16,
                              color: tokens.ink,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                strings.invitePatientBtn,
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
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // KPI Summary Strip
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '${roster.length}',
                label: strings.kpiActivePatients,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '$shiftsTotal',
                label: strings.kpiBaselineShifts,
                highlight: shiftsTotal > 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: '$unreviewedTotal',
                label: strings.kpiSharedUpdates,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Search Patients Field
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

        // Filter Pills
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
            MindPill(
              label: strings.filterSampleShort,
              isSelected: _filter == _RosterFilter.demo,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => setState(() => _filter = _RosterFilter.demo),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (filtered.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _searchQuery.trim().isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.folder_shared_outlined,
                  size: 28,
                  color: tokens.ink2,
                ),
                const SizedBox(height: 10),
                Text(
                  _searchQuery.trim().isNotEmpty
                      ? strings.noSearchMatchPatients
                      : strings.noPatientsEmptyTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.noPatientsEmptySub,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tokens.ink2,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                MindButton(
                  text: _searchQuery.trim().isNotEmpty
                      ? strings.clearFilterBtn
                      : strings.importPacketBtn,
                  variant: MindButtonVariant.soft,
                  isFullWidth: true,
                  onPressed: _searchQuery.trim().isNotEmpty
                      ? () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _filter = _RosterFilter.all;
                          });
                        }
                      : () => ImportPatientPacketSheet.show(context),
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
  }) {
    return MindCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      variant: highlight ? MindCardVariant.tint : MindCardVariant.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
    MindTokens tokens,
    AppStrings strings, {
    bool isWide = false,
    bool isSelected = false,
  }) {
    final latest = record.latestTrace;
    final recent = record.recentBaseline;
    final shifts = record.divergences(strings);
    final moodKey = latest?.overallMood ?? 'calm';
    final moodOption = trackMoodOptionFor(moodKey);
    final agenda = record.latestPacket.preVisitAgenda;
    final sleepStr = recent.averageSleepHours != null
        ? '${recent.averageSleepHours!.toStringAsFixed(1)}h'
        : '--';

    return MindCard(
      padding: const EdgeInsets.all(16),
      variant: isSelected ? MindCardVariant.tint : MindCardVariant.plain,
      borderColor: isSelected ? tokens.m1 : null,
      semanticLabel: '${record.displayName}, ${trackMoodLabel(moodKey, strings)}',
      onTap: () => _openPatientDossier(context, record, isWide: isWide),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: moodOption.color,
                ),
              ),
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.m1,
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
          const SizedBox(height: 8),
          Text(
            '${trackMoodLabel(moodKey, strings)} · '
            '${latest != null ? '${latest.moodIntensity}/10' : '--'} · '
            '${strings.metricSleepLabel}: $sleepStr · '
            '${_relativeSyncLabel(record.lastSyncedAt, strings)}',
            style: TextStyle(
              fontSize: 12.5,
              color: tokens.ink2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          _SevenDaySleepMoodStrip(
            record: record,
            sleepStr: sleepStr,
            strings: strings,
            tokens: tokens,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              MindBadge(
                icon: shifts.isNotEmpty
                    ? Icons.trending_up_rounded
                    : Icons.check_circle_outline_rounded,
                label: shifts.isNotEmpty
                    ? strings.shiftsCountBadge(shifts.length)
                    : strings.baselineSteadyBadge,
                borderColor: shifts.isNotEmpty ? tokens.safety : tokens.line,
                textColor: shifts.isNotEmpty ? tokens.safety : tokens.ink2,
              ),
              if (recent.averageSleepHours != null &&
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
  // TAB 1: COHORT OVERVIEW
  // ---------------------------------------------------------------------------
  Widget _buildCohortOverviewTab({
    required BuildContext context,
    required MindTokens tokens,
    required AppStrings strings,
    required List<ClinicianPatientRecord> roster,
    bool isWide = false,
  }) {
    final observationPairs = <(ClinicianPatientRecord, String, String)>[];
    final combinedEmotions = <String, int>{};
    final sleeps = <double>[];
    final anxieties = <double>[];
    final energies = <double>[];
    final intensities = <double>[];

    for (final record in roster) {
      final b = record.baseline;
      final r = record.recentBaseline;
      if (r.averageSleepHours != null) sleeps.add(r.averageSleepHours!);
      if (r.averageAnxietyLevel != null) anxieties.add(r.averageAnxietyLevel!);
      if (r.averageEnergyLevel != null) energies.add(r.averageEnergyLevel!);
      if (r.averageMoodIntensity != null) {
        intensities.add(r.averageMoodIntensity!);
      }
      for (final entry in b.emotionFrequencyMap.entries) {
        combinedEmotions[entry.key] =
            (combinedEmotions[entry.key] ?? 0) + entry.value;
      }
      for (final div in record.divergences(strings)) {
        observationPairs.add((record, div.title, div.baselineComparison));
      }
    }

    String avgStr(List<double> nums, [String suffix = '']) {
      if (nums.isEmpty) return '--';
      final mean = nums.reduce((a, b) => a + b) / nums.length;
      return '${mean.toStringAsFixed(1)}$suffix';
    }

    final sortedEmotions = combinedEmotions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Text(
          strings.clinicianTabOverview,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          strings.cohortAvgMetricsTitle,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: strings.isArabic ? 0 : 0.6,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: avgStr(intensities),
                label: strings.metricMoodLabel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: avgStr(sleeps, 'h'),
                label: strings.metricSleepLabel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: avgStr(anxieties),
                label: strings.metricAnxietyLabel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                tokens: tokens,
                value: avgStr(energies),
                label: strings.metricEnergyLabel,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        Text(
          strings.cohortTopFeelingsTitle,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: strings.isArabic ? 0 : 0.6,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        MindCard(
          padding: const EdgeInsets.all(14),
          child: sortedEmotions.isEmpty
              ? Text(
                  strings.noPatientsEmptySub,
                  style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedEmotions.take(8).map((entry) {
                    final label =
                        AffectTaxonomy.localizedLabel(entry.key, strings);
                    return MindBadge(label: '$label (${entry.value}x)');
                  }).toList(),
                ),
        ),

        const SizedBox(height: 18),
        Text(
          strings.cohortObservationsTitle,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: strings.isArabic ? 0 : 0.6,
            color: tokens.ink2,
          ),
        ),
        const SizedBox(height: 8),
        if (observationPairs.isEmpty)
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              strings.baselineSteadyBadge,
              style: TextStyle(fontSize: 13, color: tokens.ink2),
            ),
          )
        else
          ...observationPairs.map((item) {
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

        const SizedBox(height: 12),
        MindButton(
          text: strings.importPacketTitle,
          variant: MindButtonVariant.soft,
          leadingIcon: Icons.download_outlined,
          isFullWidth: true,
          onPressed: () => ImportPatientPacketSheet.show(context),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: PRACTICE & PRIVACY SETTINGS
  // ---------------------------------------------------------------------------
  Widget _buildPracticeTab({
    required BuildContext context,
    required MindTokens tokens,
    required AppStrings strings,
    required List<ClinicianPatientRecord> roster,
    required ClinicianProfile profile,
    required bool demoEnabled,
    required AppLockState appLock,
  }) {
    final importedCount = roster.where((r) => !r.isDemoCase).length;

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
          padding: const EdgeInsets.all(16),
          onTap: () => _editProfileSheet(context, profile, tokens, strings),
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
                      '${profile.specialty} · ${profile.clinicName}',
                      style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: tokens.ink2),
            ],
          ),
        ),

        const SizedBox(height: 14),
        // Clinic Pairing & Patient Invite Card
        MindCard(
          variant: MindCardVariant.tint,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 20, color: tokens.ink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.clinicInviteCodeTitle,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                  MindBadge(label: profile.effectiveClinicCode),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.clinicInviteCodeSub,
                style: TextStyle(
                  fontSize: 12.5,
                  color: tokens.ink2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              MindButton(
                text: strings.copyInviteMsgBtn,
                variant: MindButtonVariant.secondary,
                leadingIcon: Icons.copy_rounded,
                isFullWidth: true,
                onPressed: () =>
                    _copyClinicInvite(context, profile, tokens, strings),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        MindCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        MindCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _practiceActionRow(
                tokens: tokens,
                icon: Icons.download_outlined,
                title: strings.importPacketTitle,
                onTap: () => ImportPatientPacketSheet.show(context),
              ),
              Divider(height: 1, color: tokens.line),
              _practiceActionRow(
                tokens: tokens,
                icon: Icons.delete_outline_rounded,
                title: '${strings.clearImportedPatientsBtn} ($importedCount)',
                onTap: () => _confirmClearImported(context, tokens, strings),
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

        if (!AppEditionConfig.isClinicianApp) ...[
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

  Future<void> _copyClinicInvite(
    BuildContext context,
    ClinicianProfile profile,
    MindTokens tokens,
    AppStrings strings,
  ) async {
    HapticFeedback.mediumImpact();
    final msg = strings.clinicInviteShareMessage(
      profile.displayName,
      profile.clinicName,
      profile.effectiveClinicCode,
    );
    await Clipboard.setData(ClipboardData(text: msg));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: tokens.surface2,
          behavior: SnackBarBehavior.floating,
          content: Text(
            strings.patientInviteCopiedToast,
            style: TextStyle(color: tokens.ink, fontSize: 13),
          ),
        ),
      );
    }
  }

  Widget _practiceActionRow({
    required MindTokens tokens,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: title,
      child: MindPressable(
        onPressed: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: tokens.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 15, color: tokens.ink3),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfileSheet(
    BuildContext context,
    ClinicianProfile profile,
    MindTokens tokens,
    AppStrings strings,
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
    MindTokens tokens,
    AppStrings strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface,
        title: Text(
          strings.clearImportedPatientsBtn,
          style: TextStyle(color: tokens.ink),
        ),
        content: Text(
          strings.clearImportedPatientsConfirm,
          style: TextStyle(color: tokens.ink2, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancelBtn, style: TextStyle(color: tokens.ink2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              strings.clearImportedPatientsBtn,
              style: TextStyle(color: tokens.safety),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
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
  late final TextEditingController _clinicCodeCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
    _specCtrl = TextEditingController(text: widget.profile.specialty);
    _clinicCtrl = TextEditingController(text: widget.profile.clinicName);
    _clinicCodeCtrl = TextEditingController(
      text: widget.profile.clinicCode.isNotEmpty
          ? widget.profile.clinicCode
          : widget.profile.effectiveClinicCode,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _clinicCtrl.dispose();
    _clinicCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.sheetRadius),
        ),
        border: Border(top: BorderSide(color: tokens.line)),
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
                TextField(
                  controller: _clinicCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(fontSize: 14, color: tokens.ink),
                  decoration: InputDecoration(
                    labelText: strings.clinicInviteCodeTitle,
                  ),
                ),
                const SizedBox(height: 16),
                MindButton(
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
                              clinicCode: _clinicCodeCtrl.text
                                  .trim()
                                  .toUpperCase(),
                            ),
                          );
                      if (mounted) navigator.pop();
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
            child: SizedBox(
              height: 22,
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
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                border: Border.all(color: tokens.line),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  strings.sleep7dShortLabel(sleepStr),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
