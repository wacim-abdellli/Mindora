# Capability: Navigation Tabs, Daily Check-in & Clinician Workspace

## Overview
Defines the 5-tab patient bottom navigation bar (`ScaffoldWithNavBar`), daily check-in workflow, separated Doctor/Clinician edition (`/clinician`), and future roadmap boundary conditions.

## Requirements

### Requirement: 5 Persistent Patient Bottom Tabs
The patient application bottom navigation shell SHALL consist of five tabs:
1. **Today (`/`):** Quick daily 2-tap check-in, adaptive sleep/energy/stress pulse, post-visit care focus, and fast support shortcuts.
2. **My days (`/track`):** Mood calendar, history timeline, entry detail sheets, and non-punitive continuity view.
3. **Talk (`/investigator`):** CBT-inspired reflection companion hub (`AI Guide`) and structured cognitive deconstruction sessions (`FlashCaseScreen`).
4. **Patterns (`/insights`):** Recovery ledger, weekly rhythms, sleep-mood correlations, and shareable consultation prep.
5. **Me (`/profile`):** Settings, TRILINGUAL switcher (`AR/FR/EN`), Comfort & Larger Text display controls, clinical safety info, and local profile/care tracks.

#### Scenario: Doctor / Psychiatrist Workspace (`main_clinician.dart`)
- GIVEN the user runs or selects the Doctor / Clinician role
- THEN routing directs to `/clinician` (`ClinicianShellScreen`), keeping patient personal flows separate.

### Requirement: Daily Check-in Workflow
The system SHALL provide a daily check-in with:
1. Emotion selection from `MoodFace` (`good`, `calm`, `worried`, `annoyed`, `low`, `restless`);
2. Simple strength / intensity selection (1–10 scale);
3. Optional free-text daily note and quick context tags (Options-First, never mandatory);
4. Full local persistence via `SharedPreferences` / encrypted storage.

### Requirement: Later Features Boundary (Do NOT build prematurely)
- **Paths (v3):** Multi-week guided programs with AI-adapted pacing and reflection questions (placeholder drafts requiring professional review before release).
- **CBT Bounds:** Always describe tools as "inspired by CBT", never "CBT treatment" or "therapy", and never predict relapse.

