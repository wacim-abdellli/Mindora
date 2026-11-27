import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_switch.dart';
import '../../controllers/investigation_providers.dart';
import '../../data/direct_gemini_investigator_service.dart';
import '../../data/direct_groq_investigator_service.dart';

/// Modal bottom sheet allowing users and developers to inspect AI status,
/// test Google Gemini connectivity, switch between Live and Test Mode,
/// and securely manage their Gemini developer key.
class AiEngineConfigSheet extends ConsumerStatefulWidget {
  const AiEngineConfigSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiEngineConfigSheet(),
    );
  }

  @override
  ConsumerState<AiEngineConfigSheet> createState() => _AiEngineConfigSheetState();
}

class _AiEngineConfigSheetState extends ConsumerState<AiEngineConfigSheet> {
  late final TextEditingController _keyController;
  late final TextEditingController _proxyController;
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  late AiEngineProvider _selectedProvider;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    _selectedProvider = config.provider;
    final keyToDisplay = config.isMockKey ? '' : config.activeApiKey;
    _keyController = TextEditingController(text: keyToDisplay);
    _proxyController = TextEditingController(text: config.proxyUrl);
  }

  void _switchProvider(AiEngineProvider provider) {
    HapticFeedback.selectionClick();
    final config = ref.read(aiConfigProvider);
    final nextKey = provider == AiEngineProvider.groq
        ? config.groqApiKey
        : (config.apiKey == kDevMockGeminiKey ? '' : config.apiKey);
    setState(() {
      _selectedProvider = provider;
      _keyController.text = nextKey;
      _testResult = null;
      _testSuccess = null;
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _proxyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final strings = ref.read(appStringsProvider);
    final key = _keyController.text.trim();
    final proxy = _proxyController.text.trim();
    if (key.isEmpty && !(_selectedProvider == AiEngineProvider.groq && proxy.isNotEmpty)) {
      setState(() {
        _testResult = strings.aiEngineEmptyKeyPrompt;
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    HapticFeedback.lightImpact();

    try {
      final ({bool success, String message}) result;
      if (_selectedProvider == AiEngineProvider.groq) {
        final service = DirectGroqInvestigatorService(
          apiKey: key,
          proxyUrl: proxy,
        );
        result = await service.testConnection();
      } else {
        final service = DirectGeminiInvestigatorService(apiKey: key);
        result = await service.testConnection();
      }
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = result.success;
          _testResult = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Connection check failed: $e';
        });
      }
    }
  }

  Future<void> _saveKey() async {
    final strings = ref.read(appStringsProvider);
    final key = _keyController.text.trim();
    final proxy = _proxyController.text.trim();
    HapticFeedback.mediumImpact();
    await ref.read(aiConfigProvider.notifier).setApiKey(
          key,
          provider: _selectedProvider,
          proxyUrl: _selectedProvider == AiEngineProvider.groq ? proxy : null,
        );
    final hasLive = key.isNotEmpty ||
        (_selectedProvider == AiEngineProvider.groq && proxy.isNotEmpty);
    final providerLabel =
        _selectedProvider == AiEngineProvider.groq ? 'Groq' : 'Gemini';
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.aiEngineSavedSnackbar(providerLabel, hasLive)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearKey() async {
    final strings = ref.read(appStringsProvider);
    HapticFeedback.lightImpact();
    await ref
        .read(aiConfigProvider.notifier)
        .clearApiKey(provider: _selectedProvider);
    if (mounted) {
      _keyController.clear();
      setState(() {
        _testResult = null;
        _testSuccess = null;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.aiEngineClearedSnackbar),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final aiConfig = ref.watch(aiConfigProvider);
    final strings = ref.watch(appStringsProvider);

    final bg = tokens.surface;
    final border = tokens.line;
    final textPrimary = tokens.ink;
    final textSecondary = tokens.ink2;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.sheetRadius)),
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: tokens.m1),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.aiEngineSheetTitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: aiConfig.isLiveActive
                        ? tokens.selectedTintFor(tokens.m1)
                        : tokens.surface2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: aiConfig.isLiveActive
                          ? tokens.m1
                          : tokens.line,
                    ),
                  ),
                  child: Text(
                    aiConfig.isLiveActive
                        ? (aiConfig.provider == AiEngineProvider.groq
                            ? strings.aiEngineLiveGroqBadge
                            : strings.aiEngineLiveGeminiBadge)
                        : strings.aiEngineTestModeBadge,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: aiConfig.isLiveActive
                          ? tokens.m1
                          : tokens.ink2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              strings.aiEngineSheetSubtitle,
              style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Provider Selector (Groq vs Gemini)
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    selected: _selectedProvider == AiEngineProvider.groq,
                    label: Center(
                      child: Text(
                        strings.aiEngineGroqOption,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    onSelected: (_) => _switchProvider(AiEngineProvider.groq),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    selected: _selectedProvider == AiEngineProvider.gemini,
                    label: Center(
                      child: Text(
                        strings.aiEngineGeminiOption,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    onSelected: (_) => _switchProvider(AiEngineProvider.gemini),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mode Selector: Test Mode toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.aiEngineDevTestModeTitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.aiEngineDevTestModeSubtitle,
                          style: TextStyle(fontSize: 12.0, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  MindSwitch(
                    value: !aiConfig.useLiveAi || aiConfig.isMockKey,
                    semanticLabel: strings.aiEngineDevTestModeTitle,
                    onChanged: (isTestMode) async {
                      HapticFeedback.lightImpact();
                      await ref.read(aiConfigProvider.notifier).toggleLiveMode(!isTestMode);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _selectedProvider == AiEngineProvider.groq
                  ? strings.aiEngineGroqKeyLabel
                  : strings.aiEngineGeminiKeyLabel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              style: TextStyle(fontSize: 13, color: textPrimary),
              decoration: InputDecoration(
                hintText: _selectedProvider == AiEngineProvider.groq
                    ? 'gsk_...'
                    : 'AIza...',
                hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: tokens.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.focusRing, width: 1.5)),
                suffixIcon: IconButton(
                  tooltip: strings.isArabic
                      ? 'إظهار أو إخفاء المفتاح'
                      : (strings.isFrench ? 'Afficher/masquer la clé' : 'Toggle key visibility'),
                  icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),

            if (_selectedProvider == AiEngineProvider.groq) ...[
              const SizedBox(height: 12),
              Text(
                strings.aiEngineProxyLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _proxyController,
                keyboardType: TextInputType.url,
                style: TextStyle(fontSize: 13.5, color: textPrimary),
                decoration: InputDecoration(
                  hintText: strings.aiEngineProxyHint,
                  hintStyle: TextStyle(fontSize: 12.5, color: textSecondary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: tokens.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tokens.focusRing, width: 1.5)),
                ),
              ),
            ],

            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Builder(builder: (_) {
                final statusColor = _testSuccess == true
                    ? tokens.m1
                    : tokens.safety;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _testSuccess == true ? Icons.check_circle_outline : Icons.error_outline,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            strings.aiEngineTestConnBtn,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: tokens.ink,
                      foregroundColor: tokens.bg,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveKey,
                    child: Text(
                      strings.aiEngineSaveActivateBtn,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            if (_keyController.text.isNotEmpty || !aiConfig.isMockKey) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: tokens.safety,
                  ),
                  onPressed: _clearKey,
                  child: Text(
                    strings.aiEngineRevertMockBtn,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
