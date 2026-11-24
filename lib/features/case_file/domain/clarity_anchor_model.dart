import 'package:flutter/foundation.dart';

import '../../investigation/domain/case_model.dart';
import '../../investigation/domain/label_type.dart';
import '../../investigation/domain/statement.dart';

/// Distills a cognitive deconstruction [CaseModel] into a scannable 3-line
/// Pocket Clarity Anchor:
/// 1. Observed Fact (`[F]`)
/// 2. Mind's Jump (`[A]` / `[I]`)
/// 3. Grounded Perspective (User verdict or synthesis)
///
/// Purely descriptive and non-diagnostic. Honors [isPrivate] isolation via
/// `fromCases(..., excludePrivate: true)` whenever used in shareable contexts.
@immutable
class ClarityAnchorModel {
  const ClarityAnchorModel({
    required this.caseId,
    required this.caseNumber,
    required this.title,
    required this.observedFact,
    required this.mindsJump,
    required this.groundedPerspective,
    required this.isPrivate,
    required this.updatedAt,
  });

  final String caseId;
  final String caseNumber;
  final String title;
  final String? observedFact;
  final String? mindsJump;
  final String? groundedPerspective;
  final bool isPrivate;
  final DateTime updatedAt;

  static ClarityAnchorModel? fromCase(CaseModel c) {
    String? firstStatementByLabels(Set<LabelType> labels) {
      for (final s in c.statements) {
        if (s.speaker == StatementSpeaker.user &&
            s.label != null &&
            labels.contains(s.label) &&
            s.text.trim().isNotEmpty) {
          return s.text.trim();
        }
      }
      return null;
    }

    final factCandidate = firstStatementByLabels({LabelType.fact}) ??
        ((c.chain?.trigger ?? '').trim().isNotEmpty
            ? c.chain!.trigger.trim()
            : (c.incidentDescription.trim().isNotEmpty
                ? c.incidentDescription.trim()
                : null));

    final jumpCandidate = firstStatementByLabels({
          LabelType.assumption,
          LabelType.interpretation,
        }) ??
        ((c.chain?.thought ?? '').trim().isNotEmpty
            ? c.chain!.thought.trim()
            : null);

    // Only treat an explicit user conclusion (or a synthesized findings summary
    // paired with structured thought labels/chain) as a Grounded Perspective;
    // never misrepresent an intermediate investigator question as the user's anchor.
    final hasStructuredEvidence =
        firstStatementByLabels({
              LabelType.fact,
              LabelType.assumption,
              LabelType.interpretation,
            }) !=
            null ||
        c.chain != null;
    final groundedCandidate = (c.userConclusion ?? '').trim().isNotEmpty
        ? c.userConclusion!.trim()
        : (hasStructuredEvidence &&
                (c.findingsSummary ?? '').trim().isNotEmpty
            ? c.findingsSummary!.trim()
            : null);

    final nonNullCount = [
      factCandidate,
      jumpCandidate,
      groundedCandidate,
    ].where((e) => e != null && e.isNotEmpty).length;

    if (nonNullCount < 2) return null;

    return ClarityAnchorModel(
      caseId: c.id,
      caseNumber: c.caseNumber,
      title: c.title.trim().isNotEmpty ? c.title.trim() : c.caseNumber,
      observedFact: factCandidate,
      mindsJump: jumpCandidate,
      groundedPerspective: groundedCandidate,
      isPrivate: c.isPrivate,
      updatedAt: c.updatedAt,
    );
  }

  static List<ClarityAnchorModel> fromCases(
    List<CaseModel> cases, {
    bool excludePrivate = false,
  }) {
    final anchors = <ClarityAnchorModel>[];
    for (final c in cases) {
      if (excludePrivate && c.isPrivate) continue;
      final anchor = fromCase(c);
      if (anchor != null) {
        anchors.add(anchor);
      }
    }
    anchors.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return anchors;
  }
}
