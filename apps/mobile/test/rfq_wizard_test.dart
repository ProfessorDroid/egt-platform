import 'package:egt_mobile/src/core/storage/app_preferences.dart';
import 'package:egt_mobile/src/domain/entities/trade.dart';
import 'package:egt_mobile/src/domain/repositories/repositories.dart';
import 'package:egt_mobile/src/domain/usecases/submit_rfq.dart';
import 'package:egt_mobile/src/presentation/providers/rfq_wizard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never-touch-network repo: wizard navigation tests never submit.
class _NoSubmitRfqRepo implements RfqRepository {
  @override
  Future<Rfq> submit(RfqDraft draft) => throw UnimplementedError();

  @override
  Future<List<Rfq>> myRfqs() => throw UnimplementedError();

  @override
  Future<Rfq> getRfq(String id) => throw UnimplementedError();
}

RfqWizardController _controller({RfqDraft? prefill}) =>
    RfqWizardController(AppPreferences(), SubmitRfq(_NoSubmitRfqRepo()),
        prefill: prefill ?? RfqDraft());

void main() {
  group('RfqWizardController navigation', () {
    test('starts at step 0 with an empty draft', () {
      final c = _controller();
      expect(c.state.step, 0);
      expect(c.state.submitting, isFalse);
      expect(c.state.submitted, isNull);
    });

    test('cannot proceed past step 0 without a product', () {
      final c = _controller();
      expect(c.canProceed(0), isFalse);
      c.next();
      expect(c.state.step, 0);
    });

    test('proceeds when product, quantity, and destination are set', () {
      final draft = RfqDraft()
        ..productName = 'Cotton Wiping / Cleaning Rags'
        ..quantity = '5000'
        ..unit = 'kg'
        ..destinationCountry = 'UAE';
      final c = _controller(prefill: draft);
      expect(c.canProceed(0), isTrue);
      expect(c.canProceed(1), isTrue);
      expect(c.canProceed(4), isTrue);
      c.next();
      expect(c.state.step, 1);
      c.back();
      expect(c.state.step, 0);
    });

    test('blocks step 1 without quantity and step 4 without destination', () {
      final draft = RfqDraft()..productName = 'Glass Cleaner';
      final c = _controller(prefill: draft);
      expect(c.canProceed(1), isFalse);
      expect(c.canProceed(4), isFalse);
    });

    test('goTo clamps to the valid step range', () {
      final c = _controller();
      c.goTo(99);
      expect(c.state.step, 0);
      c.goTo(-1);
      expect(c.state.step, 0);
      c.goTo(5);
      expect(c.state.step, 5);
    });

    test('never advances past the last step', () {
      final draft = RfqDraft()
        ..productName = 'Glass Cleaner'
        ..quantity = '100'
        ..destinationCountry = 'Canada';
      final c = _controller(prefill: draft);
      for (var i = 0; i < 30; i++) {
        c.next();
      }
      expect(c.state.step, RfqWizardState.totalSteps - 1);
    });
  });

  group('RfqWizardController submit', () {
    test('offline submit never reports success and keeps the draft', () async {
      final draft = RfqDraft()
        ..productName = 'Glass Cleaner'
        ..quantity = '100'
        ..destinationCountry = 'Canada';
      final c = _controller(prefill: draft);
      final result = await c.submit(online: false);
      expect(result, isNull);
      expect(c.state.submitted, isNull);
      expect(c.state.submitError, isNotNull);
    });

    test('failed online submit records the error and rethrows', () async {
      final c = _controller();
      await expectLater(
          c.submit(online: true), throwsA(isA<UnimplementedError>()));
      expect(c.state.submitting, isFalse);
      expect(c.state.submitError, isNotNull);
    });
  });
}
