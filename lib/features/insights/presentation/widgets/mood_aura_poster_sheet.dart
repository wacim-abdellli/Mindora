import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_segmented.dart';
import '../../../../core/widgets/mind_toast.dart';
import '../../../clinician/controllers/clinician_providers.dart';
import '../../../mind_trace/domain/emotion_descriptors.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import '../../../track/presentation/widgets/track_mood_utils.dart';
import '../../domain/discovery_milestones_model.dart';

/// Privacy-safe offscreen PNG renderer (`1080x1350`, 4:5 keepsake) generating a
/// generative harmonic mood aura poster using ONLY colors, mood labels, observed
/// days, and discovery milestone counts. Never accesses journal notes or triggers.
class MoodAuraPosterRenderer {
  const MoodAuraPosterRenderer._();

  static const int width = 1080;
  static const int height = 1350;

  static Future<Uint8List> renderPng({
    required List<MindTraceModel> traces,
    required DiscoveryMilestonesSummary summary,
    required MindTokens tokens,
    required AppStrings strings,
    DateTime? referenceNow,
  }) async {
    final now = referenceNow ?? DateTime.now();
    final counts = <String, int>{};
    for (final t in traces.take(30)) {
      final key = EmotionDescriptor.canonicalKey(t.overallMood).toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      counts['calm'] = 1;
    }

    final sortedMoods = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final primaryMoodKey = sortedMoods.first.key;
    final primaryColor = MindTokens.moodColor(AppMood.fromKey(primaryMoodKey));

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // 1. Canvas ground (token-driven light/dark fidelity)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = tokens.bg,
    );

    final auraCenter = Offset(width / 2, height * 0.44);

    // 2. Ambient radial mist (smooth alpha falloff gradient without slow software blur)
    canvas.drawCircle(
      auraCenter,
      460,
      Paint()
        ..shader = ui.Gradient.radial(
          auraCenter,
          460,
          [
            primaryColor.withValues(alpha: tokens.isDark ? 0.22 : 0.26),
            primaryColor.withValues(alpha: 0.0),
          ],
        ),
    );

    // 3. Concentric harmonic wave rings driven by actual logged mood spectrum
    final ringColors = [
      for (final entry in sortedMoods.take(5))
        MindTokens.moodColor(AppMood.fromKey(entry.key)),
    ];
    for (var ringIdx = 0; ringIdx < 5; ringIdx++) {
      final color = ringColors[ringIdx % ringColors.length];
      final baseRadius = 155.0 + ringIdx * 54.0;
      final harmonics = 3.0 + (ringIdx % 4);
      final path = Path();
      const steps = 96;
      for (var i = 0; i <= steps; i++) {
        final theta = (i / steps) * 2 * math.pi;
        final wave = 0.045 * math.sin(harmonics * theta + ringIdx * 0.7) +
            0.025 * math.cos((harmonics - 1) * theta - ringIdx * 0.4);
        final r = baseRadius * (1.0 + wave);
        final pt = Offset(
          auraCenter.dx + r * math.cos(theta),
          auraCenter.dy + r * math.sin(theta),
        );
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.28 - ringIdx * 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
    }

    // 4. Sculpted inner aura orb
    final orbRadius = 148.0;
    final orbHighlight = Color.lerp(
          primaryColor,
          MindTokens.pureWhiteConstant,
          tokens.isDark ? 0.50 : 0.62,
        ) ??
        primaryColor;
    final orbDeep = Color.lerp(primaryColor, tokens.bg, 0.35) ?? primaryColor;
    canvas.drawCircle(
      auraCenter,
      orbRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(auraCenter.dx - 44, auraCenter.dy - 48),
          orbRadius * 1.45,
          [orbHighlight, primaryColor, orbDeep],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      auraCenter,
      orbRadius,
      Paint()
        ..color = orbHighlight.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final fontFamily = strings.isArabic ? 'Noto Sans Arabic' : 'Inter';
    final textDir =
        strings.isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    void drawParagraph({
      required String text,
      required double top,
      required double fontSize,
      FontWeight weight = FontWeight.w600,
      required Color color,
      TextAlign align = TextAlign.center,
    }) {
      final style = ui.ParagraphStyle(
        textAlign: align,
        textDirection: textDir,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: weight,
      );
      final builder = ui.ParagraphBuilder(style)
        ..pushStyle(ui.TextStyle(
          color: color,
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: weight,
        ))
        ..addText(text);
      final p = builder.build()
        ..layout(ui.ParagraphConstraints(width: (width - 140).toDouble()));
      canvas.drawParagraph(p, Offset(70, top));
    }

    // 5. Header + Privacy-Safe Legend Strip
    drawParagraph(
      text: strings.moodAuraHeader,
      top: 76,
      fontSize: 34,
      weight: FontWeight.w700,
      color: tokens.ink,
    );
    drawParagraph(
      text: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      top: 128,
      fontSize: 22,
      weight: FontWeight.w500,
      color: tokens.ink2,
    );

    final legendLabels = [
      for (final entry in sortedMoods.take(4))
        '${trackMoodLabel(entry.key, strings)} (${entry.value}x)',
    ].join('  ·  ');

    // Bottom info card
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(64, height - 340.0, width - 128.0, 260),
      const Radius.circular(28),
    );
    canvas.drawRRect(cardRect, Paint()..color = tokens.surface);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = tokens.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    drawParagraph(
      text: legendLabels,
      top: height - 296.0,
      fontSize: 28,
      weight: FontWeight.w700,
      color: tokens.ink,
    );
    drawParagraph(
      text:
          '${strings.moodAuraDaysLabel(summary.distinctDays)}  ·  ${strings.moodAuraMilestonesLabel(summary.unlockedCount, summary.totalCount)}',
      top: height - 224.0,
      fontSize: 25,
      weight: FontWeight.w600,
      color: primaryColor,
    );
    drawParagraph(
      text: strings.moodAuraPrivateNotice,
      top: height - 154.0,
      fontSize: 21,
      weight: FontWeight.w500,
      color: tokens.ink2,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<String> savePngToLocalFile(
    Uint8List pngBytes, {
    required String fileName,
    Directory? directory,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final targetDir = directory ?? Directory.systemTemp;
    await targetDir.create(recursive: true);
    final file = File('${targetDir.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(pngBytes, flush: true);
    return file.path;
  }
}

/// Modal preview sheet presenting the user's generative 4:5 Mood Aura PNG with
/// native OS Share and local Save actions.
class MoodAuraPosterSheet extends ConsumerStatefulWidget {
  const MoodAuraPosterSheet({
    super.key,
    required this.traces,
    required this.summary,
  });

  final List<MindTraceModel> traces;
  final DiscoveryMilestonesSummary summary;

  static Future<void> show(
    BuildContext context, {
    required List<MindTraceModel> traces,
    required DiscoveryMilestonesSummary summary,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoodAuraPosterSheet(traces: traces, summary: summary),
    );
  }

  @override
  ConsumerState<MoodAuraPosterSheet> createState() =>
      _MoodAuraPosterSheetState();
}

class _MoodAuraPosterSheetState extends ConsumerState<MoodAuraPosterSheet> {
  Uint8List? _pngBytes;
  String? _errorText;
  bool _isSharing = false;
  bool _isSaving = false;
  bool _useTwilightPoster = false;
  bool _initializedStyle = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedStyle) {
      _initializedStyle = true;
      _useTwilightPoster = context.tokens.isDark;
    }
    if (_pngBytes == null && _errorText == null) {
      _renderPoster();
    }
  }

  Future<void> _renderPoster() async {
    try {
      final posterTokens = _useTwilightPoster
          ? MindTokens.dark
          : MindTokens.light;
      final strings = ref.read(appStringsProvider);
      final bytes = await MoodAuraPosterRenderer.renderPng(
        traces: widget.traces,
        summary: widget.summary,
        tokens: posterTokens,
        strings: strings,
      );
      if (mounted) {
        setState(() {
          _pngBytes = bytes;
          _errorText = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = e.toString());
      }
    }
  }

  Future<void> _sharePoster(AppStrings strings) async {
    final bytes = _pngBytes;
    if (bytes == null) return;
    setState(() => _isSharing = true);
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = await MoodAuraPosterRenderer.savePngToLocalFile(
        bytes,
        fileName: 'mindora_mood_aura_$ts.png',
      );
      await ref.read(clinicHandoffBridgeProvider).sharePngFile(
            filePath: path,
            subject: strings.moodAuraShareSubject,
            text: strings.moodAuraShareText,
          );
      if (mounted) HapticFeedback.mediumImpact();
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _savePoster(AppStrings strings, MindTokens tokens) async {
    final bytes = _pngBytes;
    if (bytes == null) return;
    setState(() => _isSaving = true);
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'mindora_mood_aura_$ts.png';
      await MoodAuraPosterRenderer.savePngToLocalFile(bytes, fileName: fileName);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showMindToast(context, strings.moodAuraSavedSnackbar(fileName));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Icon(Icons.blur_circular_rounded, size: 20, color: tokens.m1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.moodAuraTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.moodAuraSubtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.ink2,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    child: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: tokens.ink2),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MindSegmented(
                      index: _useTwilightPoster ? 1 : 0,
                      labels: [
                        strings.sunriseStyleLabel,
                        strings.twilightStyleLabel,
                      ],
                      onChanged: (idx) {
                        final nextTwilight = idx == 1;
                        if (nextTwilight != _useTwilightPoster) {
                          setState(() {
                            _useTwilightPoster = nextTwilight;
                            _pngBytes = null;
                          });
                          _renderPoster();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    if (_errorText != null)
                      Text(
                        _errorText!,
                        style: TextStyle(fontSize: 12.5, color: tokens.safety),
                      )
                    else if (_pngBytes == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(tokens.inputRadius),
                          border: Border.all(color: tokens.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Image.memory(_pngBytes!, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 14),
                      MindButton(
                        text: strings.shareMoodAuraBtn,
                        variant: MindButtonVariant.primary,
                        leadingIcon: Icons.ios_share_rounded,
                        isFullWidth: true,
                        isLoading: _isSharing,
                        onPressed: () => _sharePoster(strings),
                      ),
                      const SizedBox(height: 10),
                      MindButton(
                        text: strings.saveMoodAuraBtn,
                        variant: MindButtonVariant.secondary,
                        leadingIcon: Icons.download_rounded,
                        isFullWidth: true,
                        isLoading: _isSaving,
                        onPressed: () => _savePoster(strings, tokens),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
