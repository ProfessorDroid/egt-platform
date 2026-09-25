import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/usecases/smart_rfq_parser.dart';
import '../../providers/core_providers.dart';

/// Smart RFQ assistant: plain-language input -> parsed preview ->
/// CONFIRMATION screen. Never silently assumes; never auto-submits.
class SmartRfqScreen extends ConsumerStatefulWidget {
  const SmartRfqScreen({super.key});

  @override
  ConsumerState<SmartRfqScreen> createState() => _SmartRfqScreenState();
}

class _SmartRfqScreenState extends ConsumerState<SmartRfqScreen> {
  final _input = TextEditingController();
  ParsedRequirement? _parsed;
  bool _analyzing = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _analyzing = true);
    // Parsing is local + instant; the delay is UX pacing only.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _parsed = SmartRfqParser.parse(text);
        _analyzing = false;
      });
    });
  }

  void _continue() {
    final p = _parsed;
    if (p == null) return;
    ref.read(analyticsProvider).logEvent('rfq_started', {'source': 'smart'});
    final params = <String, String>{
      if (p.productName != null) 'smartProduct': p.productName!,
      if (p.quantity != null) 'quantity': p.quantity!,
      if (p.unit != null) 'unit': p.unit!,
      if (p.destination != null) 'destination': p.destination!,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    context.push('/rfq/new${query.isEmpty ? '' : '?$query'}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.smartTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.smartExample,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: EgtColors.steel)),
                  const SizedBox(height: EgtDimens.s12),
                  EgtTextField(
                    hint: l10n.smartHint,
                    controller: _input,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _parse(),
                  ),
                  const SizedBox(height: EgtDimens.s12),
                  EgtButton(
                      label: l10n.actionContinue,
                      icon: Icons.auto_awesome_outlined,
                      onPressed: _parse,
                      isLoading: _analyzing),
                  if (_parsed != null) ...[
                    const SizedBox(height: EgtDimens.s24),
                    _ConfirmationCard(
                      parsed: _parsed!,
                      onConfirm: _continue,
                      onStartOver: () => setState(() {
                        _parsed = null;
                        _input.clear();
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.parsed,
    required this.onConfirm,
    required this.onStartOver,
  });

  final ParsedRequirement parsed;
  final VoidCallback onConfirm;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lowConfidence = parsed.confidence < 0.5;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(EgtDimens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined,
                    color: EgtColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.smartConfirmTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.smartConfirmBody,
                style: Theme.of(context).textTheme.bodySmall),
            if (lowConfidence) ...[
              const SizedBox(height: 12),
              StatusChip.warning(l10n.smartLowConfidence),
            ],
            const SizedBox(height: 12),
            _row(context, l10n.smartProduct, parsed.productName),
            _row(context, l10n.smartQuantity,
                [parsed.quantity, parsed.unit]
                    .whereType<String>()
                    .join(' ')),
            _row(context, l10n.smartDestination, parsed.destination),
            if (!parsed.hasProduct &&
                !parsed.hasQuantity &&
                !parsed.hasDestination) ...[
              const SizedBox(height: 8),
              Text(l10n.smartNotUnderstood,
                  style: const TextStyle(color: EgtColors.error)),
            ],
            const SizedBox(height: 16),
            EgtButton(label: l10n.smartUseAsIs, onPressed: onConfirm),
            const SizedBox(height: 8),
            EgtOutlineButton(
                label: l10n.smartStartOver, onPressed: onStartOver),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 110,
                child: Text(label,
                    style: Theme.of(context).textTheme.labelMedium)),
            Expanded(
              child: Text(value == null || value.isEmpty ? '—' : value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
