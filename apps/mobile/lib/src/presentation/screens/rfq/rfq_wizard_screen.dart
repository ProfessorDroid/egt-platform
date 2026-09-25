import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/step_progress.dart';
import '../../../domain/entities/trade.dart';
import '../../providers/core_providers.dart';
import '../../providers/rfq_wizard_provider.dart';
import 'rfq_wizard_steps.dart';

/// 12-step RFQ wizard shell: progress, step content, back/next, submit.
/// Prefill via query params: productId, productName, quantity, unit,
/// destination, categoryName (custom product).
class RfqWizardScreen extends ConsumerWidget {
  const RfqWizardScreen({super.key});

  RfqDraft _prefillFromQuery(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    final draft = RfqDraft();
    final productId = params['productId'];
    if (productId != null && productId.isNotEmpty) {
      draft.productId = productId;
      draft.productName = params['productName'];
    }
    final categoryName = params['categoryName'];
    if (categoryName != null && categoryName.isNotEmpty) {
      draft.customProductDetails = categoryName;
    }
    final smartProduct = params['smartProduct'];
    if (smartProduct != null && smartProduct.isNotEmpty) {
      draft.productName = smartProduct;
    }
    if (params['quantity'] != null) draft.quantity = params['quantity'];
    if (params['unit'] != null) draft.unit = params['unit'];
    if (params['destination'] != null) {
      draft.destinationCountry = params['destination'];
    }
    return draft;
  }

  bool _hasPrefill(BuildContext context) =>
      GoRouterState.of(context).uri.queryParameters.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hasPrefill = _hasPrefill(context);
    final RfqWizardState state;
    final RfqWizardController controller;
    if (hasPrefill) {
      final prefilled = rfqWizardPrefilledProvider(_prefillFromQuery(context));
      state = ref.watch(prefilled);
      controller = ref.read(prefilled.notifier);
    } else {
      state = ref.watch(rfqWizardProvider);
      controller = ref.read(rfqWizardProvider.notifier);
    }
    final online = ref.watch(isOnlineProvider).maybeWhen(
          data: (v) => v,
          orElse: () => true,
        );
    final titles = rfqStepTitles(context);
    final isLast = state.step == RfqWizardState.totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rfqTitle),
        actions: [
          TextButton(
            onPressed: () async {
              final discard = await showConfirmDialog(
                context,
                title: l10n.rfqDiscard,
                body: l10n.rfqDiscard,
                destructive: true,
              );
              if (discard) {
                await controller.clearDraft();
                if (context.mounted) context.pop();
              }
            },
            child: Text(l10n.rfqDiscard,
                style: const TextStyle(color: EgtColors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: StepProgress(
              current: state.step,
              total: RfqWizardState.totalSteps,
              label: titles[state.step],
              stepText: l10n.rfqStep(state.step + 1, RfqWizardState.totalSteps),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              child: _stepContent(
                state.step,
                state.draft,
                controller.updateDraft,
                (s) => controller.goTo(s),
                online,
                state.submitting,
                state.submitError,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (state.step > 0)
                    Expanded(
                      child: EgtOutlineButton(
                          label: l10n.actionBack,
                          onPressed: controller.back),
                    ),
                  if (state.step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: isLast
                        ? EgtButton(
                            label: l10n.rfqSubmitCta,
                            isLoading: state.submitting,
                            onPressed: (state.submitting || !online)
                                ? null
                                : () => _submit(context, ref, controller, online),
                          )
                        : EgtButton(
                            label: l10n.actionNext,
                            onPressed: controller.canProceed(state.step)
                                ? controller.next
                                : null,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContent(
    int step,
    RfqDraft draft,
    DraftUpdate update,
    void Function(int) jump,
    bool online,
    bool submitting,
    String? submitError,
  ) {
    switch (step) {
      case 0:
        return RfqProductStep(draft: draft, update: update);
      case 1:
        return RfqQuantityStep(draft: draft, update: update);
      case 2:
        return RfqPackagingStep(draft: draft, update: update);
      case 3:
        return RfqPrivateLabelStep(draft: draft, update: update);
      case 4:
        return RfqDestinationStep(draft: draft, update: update);
      case 5:
        return RfqPortStep(draft: draft, update: update);
      case 6:
        return RfqIncotermStep(draft: draft, update: update);
      case 7:
        return RfqSpecsStep(draft: draft, update: update);
      case 8:
        return RfqDocumentsStep(draft: draft, update: update);
      case 9:
        return RfqNotesStep(draft: draft, update: update);
      case 10:
        return RfqReviewStep(draft: draft, onJump: jump);
      default:
        return RfqSubmitStep(
          draft: draft,
          online: online,
          submitting: submitting,
          submitError: submitError,
        );
    }
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    RfqWizardController controller,
    bool online,
  ) async {
    final l10n = context.l10n;
    try {
      final rfq = await controller.submit(online: online);
      if (rfq == null) return; // offline — draft kept, message shown
      ref.read(analyticsProvider).logEvent('rfq_completed', {'rfq_id': rfq.id});
      if (context.mounted) context.go('/rfq/result/${rfq.id}');
    } on AppException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }
  }
}
