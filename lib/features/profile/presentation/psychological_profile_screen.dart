import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import 'psychological_profile_view.dart';

/// Top-level Screen wrapper for [PsychologicalProfileView].
class PsychologicalProfileScreen extends ConsumerWidget {
  const PsychologicalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(
          strings.myPsychologicalProfileTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: strings.isArabic ? 0 : -0.2,
            color: tokens.ink,
          ),
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: const SafeArea(
        child: PsychologicalProfileView(),
      ),
    );
  }
}

