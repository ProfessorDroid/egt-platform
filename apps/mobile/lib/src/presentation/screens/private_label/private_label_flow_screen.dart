import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/step_progress.dart';
import '../../../domain/entities/growth.dart';
import '../../providers/core_providers.dart';
import '../../providers/growth_providers.dart';

/// 9-step private-label flow mapped to the domain [PrivateLabelDraft]:
/// product → brand → packaging → size → label requirements → quantity →
/// destination → artwork → submit. The request is submitted only after backend
/// confirmation; offline shows an explicit failure message instead of fake
/// success.
class PrivateLabelFlowScreen extends ConsumerStatefulWidget {
  const PrivateLabelFlowScreen({super.key});

  @override
  ConsumerState<PrivateLabelFlowScreen> createState() =>
      _PrivateLabelFlowScreenState();
}

class _PrivateLabelFlowScreenState
    extends ConsumerState<PrivateLabelFlowScreen> {
  final _page = PageController();
  final _draft = PrivateLabelDraft();
  int _step = 0;
  bool _busy = false;

  final _product = TextEditingController();
  final _brand = TextEditingController();
  final _packaging = TextEditingController();
  final _size = TextEditingController();
  final _label = TextEditingController();
  final _quantity = TextEditingController();
  final _destination = TextEditingController();

  static const int totalSteps = 9;

  @override
  void dispose() {
    _page.dispose();
    _product.dispose();
    _brand.dispose();
    _packaging.dispose();
    _size.dispose();
    _label.dispose();
    _quantity.dispose();
    _destination.dispose();
    super.dispose();
  }

  List<String> _titles(AppLocalizations l) => [
        l.plStepProduct,
        l.plStepBrand,
        l.plStepPackaging,
        l.plStepSize,
        l.plStepLabel,
        l.plStepQuantity,
        l.plStepDestination,
        l.plStepArtwork,
        l.plStepSubmit,
      ];

  bool _canAdvance() {
    if (_step == 0) return _product.text.trim().length >= 3;
    if (_step == 5) return _quantity.text.trim().isNotEmpty;
    return true;
  }

  void _syncDraft() {
    _draft.productName = _product.text.trim();
    _draft.brandName = _brand.text.trim();
    _draft.packagingType = _packaging.text.trim();
    _draft.size = _size.text.trim();
    _draft.labelRequirements = _label.text.trim();
    _draft.quantity = _quantity.text.trim();
    _draft.destinationCountry = _destination.text.trim();
  }

  Future<void> _pickArtwork() async {
    try {
      final files = await ImagePicker().pickMultiImage(limit: 5);
      if (files.isEmpty) return;
      setState(() => _draft.artworkPaths = [
            ..._draft.artworkPaths,
            ...files.map((f) => f.path),
          ]);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorGeneric)));
      }
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final online = ref.read(connectivityServiceProvider).isOnline;
    if (!online) {
      // Never fake success offline: explicit failure, draft kept locally.
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.rfqOfflineBlocked)));
      }
      return;
    }
    _syncDraft();
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.plSubmitTitle,
      body: l10n.plSubmitBody,
      confirmLabel: l10n.actionSubmit,
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      final request =
          await ref.read(privateLabelRepositoryProvider).submit(_draft);
      ref.read(analyticsProvider).logEvent(
          'private_label_request_created', {'request_id': request.id});
      if (mounted) context.go('/private-label');
    } on AppException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = _titles(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.plTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: StepProgress(
              current: _step,
              total: totalSteps,
              label: titles[_step],
              stepText: l10n.tr('rfq_step',
                  {'current': '${_step + 1}', 'total': '$totalSteps'}),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) {
                _syncDraft();
                setState(() => _step = i);
              },
              children: [
                _stepPage([
                  EgtTextField(
                      hint: l10n.plProductHint, controller: _product),
                ]),
                _stepPage([
                  EgtTextField(
                      hint: l10n.plBrandHint, controller: _brand),
                ]),
                _stepPage([
                  EgtTextField(
                      hint: l10n.plPackagingHint,
                      controller: _packaging,
                      maxLines: 3),
                ]),
                _stepPage([
                  EgtTextField(
                      hint: l10n.plStepSize, controller: _size),
                ]),
                _stepPage([
                  EgtTextField(
                      hint: l10n.plStepLabel,
                      controller: _label,
                      maxLines: 3),
                ]),
                _stepPage([
                  EgtTextField(
                      hint: l10n.plQuantityHint,
                      controller: _quantity,
                      keyboardType: TextInputType.number),
                ]),
                _stepPage([
                  EgtTextField(
                      hint: l10n.plStepDestination,
                      controller: _destination),
                ]),
                _stepPage([
                  Text(l10n.plArtworkHint,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  EgtOutlineButton(
                      label: l10n.plUploadLogo,
                      icon: Icons.upload_file_outlined,
                      onPressed: _pickArtwork),
                  if (_draft.artworkPaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final p in _draft.artworkPaths)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(p.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() =>
                                  _draft.artworkPaths.remove(p)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ]),
                _stepPage([_review(l10n)]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(EgtDimens.s16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: EgtOutlineButton(
                        label: l10n.actionBack,
                        onPressed: () => _page.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut)),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: _step == totalSteps - 1
                      ? EgtButton(
                          label: l10n.actionSubmit,
                          onPressed: _submit,
                          isLoading: _busy)
                      : EgtButton(
                          label: l10n.actionContinue,
                          onPressed: _canAdvance()
                              ? () => _page.nextPage(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeOut)
                              : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepPage(List<Widget> children) => SingleChildScrollView(
        padding: const EdgeInsets.all(EgtDimens.s16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _review(AppLocalizations l10n) {
    _syncDraft();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(EgtDimens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(l10n.plStepProduct, _draft.productName ?? '—'),
            _kv(l10n.plStepBrand, _draft.brandName ?? '—'),
            _kv(l10n.plStepPackaging, _draft.packagingType ?? '—'),
            _kv(l10n.plStepSize, _draft.size ?? '—'),
            _kv(l10n.plStepLabel, _draft.labelRequirements ?? '—'),
            _kv(l10n.plStepQuantity, _draft.quantity ?? '—'),
            _kv(l10n.plStepDestination, _draft.destinationCountry ?? '—'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(k,
                    style: Theme.of(context).textTheme.labelMedium)),
            Expanded(child: Text(v.isEmpty ? '—' : v)),
          ],
        ),
      );
}
