import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../domain/entities/catalog.dart';
import '../../../domain/entities/trade.dart';
import '../../providers/catalog_providers.dart';

/// Step titles in wizard order (12 steps).
List<String> rfqStepTitles(BuildContext context) {
  final l = context.l10n;
  return [
    l.rfqStepProduct,
    l.rfqStepQuantity,
    l.rfqStepPackaging,
    l.rfqStepPrivateLabel,
    l.rfqStepDestination,
    l.rfqStepPort,
    l.rfqStepIncoterm,
    l.rfqStepSpecs,
    l.rfqStepDocuments,
    l.rfqStepNotes,
    l.rfqStepReview,
    l.rfqStepSubmit,
  ];
}

typedef DraftUpdate = void Function(void Function(RfqDraft d));

const _units = [
  'kg', 'g', 'MT', 'tons', 'L', 'mL',
  'pieces', 'bottles', 'cartons', 'boxes', 'units', 'bags', 'pallets', 'drums',
];

final _productSearchProvider = StateProvider<String>((ref) => '');

final _productOptionsProvider = FutureProvider<List<Product>>((ref) {
  final q = ref.watch(_productSearchProvider);
  return ref
      .watch(catalogRepositoryProvider)
      .getProducts(query: q.isEmpty ? null : q);
});

// ---------- Step 0: product ----------
class RfqProductStep extends ConsumerWidget {
  const RfqProductStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final options = ref.watch(_productOptionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqProductLabel,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        EgtTextField(
          hint: l10n.rfqProductHint,
          prefixIcon: Icons.search,
          onChanged: (v) =>
              ref.read(_productSearchProvider.notifier).state = v,
        ),
        const SizedBox(height: EgtDimens.s8),
        options.maybeWhen(
          data: (products) => SizedBox(
            height: 220,
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = products[i];
                final selected = draft.productId == p.id;
                return ListTile(
                  leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: EgtProductImage(
                          productId: p.id,
                          imageUrl: p.imageUrl,
                          localAssetKey: p.localAssetKey,
                          borderRadius: 6)),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(p.category),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: EgtColors.success)
                      : null,
                  selected: selected,
                  onTap: () => update((d) {
                    d.productId = p.id;
                    d.productName = p.name;
                    d.customProductDetails = null;
                  }),
                );
              },
            ),
          ),
          orElse: () => const SizedBox(
              height: 220, child: Center(child: CircularProgressIndicator())),
        ),
        const SizedBox(height: EgtDimens.s16),
        Text(l10n.rfqProductCustom,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        EgtTextField(
          hint: l10n.rfqProductCustom,
          initialValue: draft.customProductDetails,
          maxLines: 3,
          onChanged: (v) => update((d) {
            d.customProductDetails = v.isEmpty ? null : v;
            if (v.isNotEmpty) {
              d.productId = null;
              d.productName = null;
            }
          }),
        ),
      ],
    );
  }
}

// ---------- Step 1: quantity ----------
class RfqQuantityStep extends StatelessWidget {
  const RfqQuantityStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepQuantity,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: EgtTextField(
                label: l10n.rfqQtyLabel,
                hint: l10n.rfqQtyHint,
                initialValue: draft.quantity,
                keyboardType: TextInputType.number,
                onChanged: (v) => update((d) => d.quantity = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.rfqUnitLabel,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _units.contains(draft.unit) ? draft.unit : null,
                    hint: Text(l10n.rfqUnitLabel),
                    items: _units
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => update((d) => d.unit = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------- Step 2: packaging ----------
class RfqPackagingStep extends StatelessWidget {
  const RfqPackagingStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  static const _suggestions = [
    '25 kg bags',
    '50 kg bags',
    '200 L drums',
    'IBC tanks',
    'Retail bottles',
    'Cartons',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepPackaging,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        EgtTextField(
          label: l10n.rfqPackagingLabel,
          hint: l10n.rfqPackagingHint,
          initialValue: draft.packaging,
          onChanged: (v) => update((d) => d.packaging = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map((s) => ChoiceChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    selected: draft.packaging == s,
                    onSelected: (_) => update((d) => d.packaging = s),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ---------- Step 3: private label ----------
class RfqPrivateLabelStep extends StatelessWidget {
  const RfqPrivateLabelStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepPrivateLabel,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        Text(l10n.rfqPrivateLabelLabel),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.rfqYes)),
            ButtonSegment(value: false, label: Text(l10n.rfqNo)),
          ],
          selected: {draft.privateLabel},
          onSelectionChanged: (s) =>
              update((d) => d.privateLabel = s.first),
        ),
      ],
    );
  }
}

// ---------- Step 4: destination country ----------
class RfqDestinationStep extends StatelessWidget {
  const RfqDestinationStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepDestination,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        EgtTextField(
          label: l10n.rfqCountryLabel,
          initialValue: draft.destinationCountry,
          prefixIcon: Icons.public_outlined,
          textInputAction: TextInputAction.next,
          onChanged: (v) => update((d) => d.destinationCountry = v),
        ),
      ],
    );
  }
}

// ---------- Step 5: port ----------
class RfqPortStep extends StatelessWidget {
  const RfqPortStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepPort,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        EgtTextField(
          label: l10n.rfqPortLabel,
          initialValue: draft.destinationPort,
          prefixIcon: Icons.anchor_outlined,
          onChanged: (v) => update((d) => d.destinationPort = v),
        ),
      ],
    );
  }
}

// ---------- Step 6: incoterm ----------
class RfqIncotermStep extends StatelessWidget {
  const RfqIncotermStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = {
      Incoterm.exw: l10n.incotermExw,
      Incoterm.fob: l10n.incotermFob,
      Incoterm.cif: l10n.incotermCif,
      Incoterm.ddp: l10n.incotermDdp,
      Incoterm.other: l10n.incotermOther,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepIncoterm,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        Text(l10n.rfqIncotermLabel),
        const SizedBox(height: 8),
        for (final entry in options.entries)
          RadioListTile<Incoterm>(
            value: entry.key,
            groupValue: draft.incoterm,
            title: Text(entry.value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            activeColor: EgtColors.red,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) =>
                update((d) => d.incoterm = v ?? Incoterm.fob),
          ),
      ],
    );
  }
}

// ---------- Step 7: specs ----------
class RfqSpecsStep extends StatelessWidget {
  const RfqSpecsStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepSpecs,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        EgtTextField(
          label: l10n.rfqSpecsLabel,
          hint: l10n.rfqSpecsHint,
          initialValue: draft.specs,
          maxLines: 5,
          onChanged: (v) => update((d) => d.specs = v),
        ),
      ],
    );
  }
}

// ---------- Step 8: documents ----------
class RfqDocumentsStep extends ConsumerWidget {
  const RfqDocumentsStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    final paths =
        result.files.map((f) => f.path).whereType<String>().toList();
    update((d) => d.attachmentPaths = [...d.attachmentPaths, ...paths]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepDocuments,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        Text(l10n.rfqDocumentsHint,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _pick(context, ref),
          icon: const Icon(Icons.attach_file),
          label: Text(l10n.rfqDocumentsAdd),
        ),
        const SizedBox(height: 12),
        for (final path in draft.attachmentPaths)
          Card(
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(path.split('/').last,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => update((d) => d.attachmentPaths =
                    d.attachmentPaths.where((p) => p != path).toList()),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------- Step 9: notes ----------
class RfqNotesStep extends StatelessWidget {
  const RfqNotesStep({super.key, required this.draft, required this.update});
  final RfqDraft draft;
  final DraftUpdate update;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepNotes,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        EgtTextField(
          label: l10n.rfqNotesLabel,
          hint: l10n.rfqNotesHint,
          initialValue: draft.notes,
          maxLines: 5,
          onChanged: (v) => update((d) => d.notes = v),
        ),
      ],
    );
  }
}

// ---------- Step 10: review ----------
class RfqReviewStep extends StatelessWidget {
  const RfqReviewStep({
    super.key,
    required this.draft,
    required this.onJump,
  });
  final RfqDraft draft;
  final void Function(int step) onJump;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String label, String value, int step)>[
      (l10n.rfqStepProduct, draft.displayProduct, 0),
      (l10n.rfqStepQuantity, draft.displayQuantity, 1),
      (l10n.rfqStepPackaging, draft.packaging ?? '—', 2),
      (l10n.rfqStepPrivateLabel,
          draft.privateLabel ? l10n.rfqYes : l10n.rfqNo, 3),
      (l10n.rfqStepDestination, draft.displayDestination, 4),
      (l10n.rfqStepIncoterm, draft.incoterm.key, 6),
      (l10n.rfqStepSpecs, draft.specs ?? '—', 7),
      (l10n.rfqStepNotes, draft.notes ?? '—', 9),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqReviewTitle,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        Card(
          child: Column(
            children: [
              for (final row in rows)
                ListTile(
                  title: Text(row.$1,
                      style: Theme.of(context).textTheme.labelMedium),
                  subtitle: Text(row.$2,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () => onJump(row.$3),
                  dense: true,
                ),
              if (draft.attachmentPaths.isNotEmpty)
                ListTile(
                  title: Text(l10n.rfqStepDocuments,
                      style: Theme.of(context).textTheme.labelMedium),
                  subtitle: Text(
                      '${draft.attachmentPaths.length} file(s)',
                      style: Theme.of(context).textTheme.bodyMedium),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () => onJump(8),
                  dense: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- Step 11: submit ----------
class RfqSubmitStep extends StatelessWidget {
  const RfqSubmitStep({
    super.key,
    required this.draft,
    required this.online,
    required this.submitting,
    required this.submitError,
  });
  final RfqDraft draft;
  final bool online;
  final bool submitting;
  final String? submitError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rfqStepSubmit,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: EgtDimens.s12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(EgtDimens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(context, l10n.rfqResultProduct, draft.displayProduct),
                _line(context, l10n.rfqResultQuantity,
                    draft.displayQuantity),
                _line(context, l10n.rfqResultDestination,
                    draft.displayDestination),
                _line(context, l10n.rfqStepIncoterm, draft.incoterm.key),
              ],
            ),
          ),
        ),
        if (!online) ...[
          const SizedBox(height: EgtDimens.s12),
          Container(
            padding: const EdgeInsets.all(EgtDimens.s12),
            decoration: BoxDecoration(
              color: EgtColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(EgtDimens.radius),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: EgtColors.warning),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(l10n.rfqOfflineBlocked,
                        style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ],
        if (submitError != null && submitError != 'offline') ...[
          const SizedBox(height: EgtDimens.s12),
          StatusChip.negative(l10n.errorGeneric),
        ],
        if (submitting) ...[
          const SizedBox(height: EgtDimens.s16),
          Row(
            children: [
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4)),
              const SizedBox(width: 12),
              Text(l10n.rfqSubmitting),
            ],
          ),
        ],
      ],
    );
  }

  Widget _line(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(label,
                    style: Theme.of(context).textTheme.labelMedium)),
            Expanded(
                child: Text(value,
                    style:
                        Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}
