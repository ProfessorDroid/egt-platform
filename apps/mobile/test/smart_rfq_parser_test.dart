import 'package:egt_mobile/src/domain/usecases/smart_rfq_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmartRfqParser', () {
    test('parses product, quantity, and destination from plain English', () {
      final r = SmartRfqParser.parse(
          'I need 5,000 kg cotton wiping rags for UAE');
      expect(r.productName, 'Cotton Wiping / Cleaning Rags');
      expect(r.quantity, '5000');
      expect(r.unit, 'kg');
      expect(r.destination, isNotNull);
      expect(r.destination!.toLowerCase(), contains('uae'));
      expect(r.confidence, 1.0);
    });

    test('maps keywords only to audited catalogue products', () {
      final r = SmartRfqParser.parse('need carnauba liquid wax 200 L');
      expect(r.productName, 'Hydro-Shield Carnauba Liquid Wax');
      expect(r.quantity, '200');
      expect(r.unit, 'L');
    });

    test('empty input yields zero confidence and no fields', () {
      const r = ParsedRequirement(raw: '', confidence: 0);
      final parsed = SmartRfqParser.parse('   ');
      expect(parsed.productName, isNull);
      expect(parsed.quantity, isNull);
      expect(parsed.destination, isNull);
      expect(parsed.confidence, 0);
      expect(r.confidence, 0);
    });

    test('partial input lowers confidence and flags low-confidence UI', () {
      final r = SmartRfqParser.parse('floor cleaner');
      expect(r.productName, 'Dr. Clenzol Multi-Surface Floor Cleaner');
      expect(r.quantity, isNull);
      expect(r.destination, isNull);
      expect(r.confidence, lessThan(0.5));
    });

    test('never invents a product for unknown input', () {
      final r = SmartRfqParser.parse('quantum flux capacitors 10 pieces');
      expect(r.productName, isNull);
      expect(r.quantity, '10');
      expect(r.unit, 'pieces');
      expect(r.confidence, lessThan(0.5));
    });

    test('normalizes units consistently', () {
      expect(SmartRfqParser.parse('att a 2 MT for Canada').unit, 'MT');
      expect(SmartRfqParser.parse('glass cleaner 500 ml').unit, 'mL');
      expect(SmartRfqParser.parse('dishwash 50 bottles').unit, 'bottles');
    });

    test('strips thousand separators from quantities', () {
      final r = SmartRfqParser.parse('potato 25,000 kg');
      expect(r.quantity, '25000');
      expect(r.productName, 'Export-Grade Fresh Table & Processing Potatoes');
    });
  });
}
