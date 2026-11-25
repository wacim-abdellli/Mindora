import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_chip.dart';
import '../../../../core/widgets/mind_sheet.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../../profile/domain/psychological_profile_model.dart';

/// Modal bottom sheet letting users choose how Mindora listens & replies.
class CustomAiInstructionsSheet extends ConsumerStatefulWidget {
  const CustomAiInstructionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showMindSheet<void>(
      context: context,
      showCloseButton: true,
      builder: (_) => const CustomAiInstructionsSheet(),
    );
  }

  @override
  ConsumerState<CustomAiInstructionsSheet> createState() =>
      _CustomAiInstructionsSheetState();
}

class _CustomAiInstructionsSheetState
    extends ConsumerState<CustomAiInstructionsSheet> {
  late final TextEditingController _instructionsController;
  bool _isSaving = false;

  static const List<({String label, String directive})> _presets = [
    (
      label: 'Short & calm',
      directive:
          'Keep replies under 3 sentences. Focus on breathing and simple present-moment steps.',
    ),
    (
      label: 'Gentle & warm',
      directive:
          'Respond with warmth and patience before suggesting another way to look at things.',
    ),
    (
      label: 'Step-by-step clarity',
      directive:
          'Ask one gentle question at a time to help separate facts from worry stories.',
    ),
    (
      label: 'Direct & practical',
      directive:
          'Be clear, friendly, and practical with one small action I can try right now.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).value;
    _instructionsController = TextEditingController(
      text: profile?.customAiDirectives ?? '',
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    final current =
        ref.read(profileControllerProvider).value ??
        PsychologicalProfileModel.empty();
    final updated = current.copyWith(
      customAiDirectives: _instructionsController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await ref.read(profileControllerProvider.notifier).saveFullProfile(updated);

    if (mounted) {
      final strings = ref.read(appStringsProvider);
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      showMindToast(context, strings.customInstructionsSavedToast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.listeningPrefsLabel,
            style: LabTheme.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.shareWithAiDesc,
            style: LabTheme.textStyle(
              fontSize: 14.5,
              height: 1.45,
              color: tokens.ink2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _presets)
                MindChip(
                  label: preset.label,
                  selected:
                      _instructionsController.text.trim() == preset.directive,
                  onTap: () => setState(
                    () => _instructionsController.text = preset.directive,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _instructionsController,
            maxLines: 3,
            style: LabTheme.textStyle(
              color: tokens.ink,
              fontSize: 15,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: strings.quickNoteQuestion,
            ),
          ),
          const SizedBox(height: 18),
          MindButton(
            text: strings.saveDetailsBtn,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
