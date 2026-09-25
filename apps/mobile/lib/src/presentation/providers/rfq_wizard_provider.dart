import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_preferences.dart';
import '../../domain/entities/trade.dart';
import '../../domain/usecases/submit_rfq.dart';
import './core_providers.dart';
import './trade_providers.dart';

/// 12-step RFQ wizard state.
class RfqWizardState {
  const RfqWizardState({
    required this.draft,
    this.step = 0,
    this.submitting = false,
    this.submitError,
    this.submitted,
  });

  final RfqDraft draft;
  final int step;
  final bool submitting;
  final String? submitError;
  final Rfq? submitted;

  static const int totalSteps = 12;

  RfqWizardState copyWith({
    RfqDraft? draft,
    int? step,
    bool? submitting,
    String? submitError,
    Rfq? submitted,
  }) =>
      RfqWizardState(
        draft: draft ?? this.draft,
        step: step ?? this.step,
        submitting: submitting ?? this.submitting,
        submitError: submitError,
        submitted: submitted ?? this.submitted,
      );
}

class RfqWizardController extends StateNotifier<RfqWizardState> {
  RfqWizardController(
    this._prefs,
    this._submitRfq, {
    RfqDraft? prefill,
  }) : super(RfqWizardState(draft: prefill ?? RfqDraft())) {
    if (prefill == null) _restoreDraft();
  }

  final AppPreferences _prefs;
  final SubmitRfq _submitRfq;

  Future<void> _restoreDraft() async {
    final json = await _prefs.readRfqDraft();
    if (json == null) return;
    try {
      final draft = RfqDraft.fromJson(
          Map<String, dynamic>.from(jsonDecode(json) as Map));
      state = state.copyWith(draft: draft);
    } catch (_) {
      // Corrupt draft — start fresh.
    }
  }

  Future<void> _persist() async {
    try {
      await _prefs.saveRfqDraft(jsonEncode(state.draft.toJson()));
    } catch (_) {}
  }

  void updateDraft(RfqDraft Function(RfqDraft d) fn) {
    final draft = state.draft;
    fn(draft);
    state = state.copyWith(draft: draft);
    _persist();
  }

  void next() {
    if (state.step < RfqWizardState.totalSteps - 1 && canProceed(state.step)) {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void back() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  void goTo(int step) {
    if (step >= 0 && step < RfqWizardState.totalSteps) {
      state = state.copyWith(step: step);
    }
  }

  /// Per-step validation. Product, quantity, and destination country are required.
  bool canProceed(int step) {
    final d = state.draft;
    switch (step) {
      case 0:
        return d.isProductStepValid;
      case 1:
        return d.quantity != null && d.quantity!.trim().isNotEmpty;
      case 4:
        return d.destinationCountry != null &&
            d.destinationCountry!.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> clearDraft() async {
    await _prefs.clearRfqDraft();
    state = RfqWizardState(draft: RfqDraft());
  }

  /// Submits the draft. Returns the created RFQ only after backend
  /// confirmation — never reports success earlier.
  Future<Rfq?> submit({required bool online}) async {
    if (!online) {
      state = state.copyWith(submitError: 'offline');
      return null;
    }
    state = state.copyWith(submitting: true, submitError: null);
    try {
      final rfq = await _submitRfq(state.draft);
      await _prefs.clearRfqDraft();
      state = state.copyWith(submitting: false, submitted: rfq);
      return rfq;
    } catch (e) {
      state = state.copyWith(submitting: false, submitError: e.toString());
      rethrow;
    }
  }
}

final rfqWizardProvider = StateNotifierProvider.autoDispose<
    RfqWizardController, RfqWizardState>((ref) {
  return RfqWizardController(
    ref.watch(appPreferencesProvider),
    SubmitRfq(ref.watch(rfqRepositoryProvider)),
  );
});

/// Prefilled variant (from product page / smart assistant / deep link).
final rfqWizardPrefilledProvider = StateNotifierProvider.autoDispose
    .family<RfqWizardController, RfqWizardState, RfqDraft>((ref, prefill) {
  return RfqWizardController(
    ref.watch(appPreferencesProvider),
    SubmitRfq(ref.watch(rfqRepositoryProvider)),
    prefill: prefill,
  );
});
