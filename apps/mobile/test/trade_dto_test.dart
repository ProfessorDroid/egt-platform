import 'package:egt_mobile/src/data/dto/trade_dto.dart';
import 'package:egt_mobile/src/domain/entities/trade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RfqDto', () {
    test('maps backend JSON to the Rfq entity', () {
      final dto = RfqDto.fromJson({
        'id': 'rfq_123',
        'productName': 'Cotton Wiping / Cleaning Rags',
        'quantity': '5000 kg',
        'destination': 'Jebel Ali, UAE',
        'status': 'quoted',
        'submittedAt': '2026-09-20T10:30:00Z',
        'assignee': 'Trade Desk',
        'nextStep': 'Review quotation',
      });
      final rfq = dto.toEntity();
      expect(rfq.id, 'rfq_123');
      expect(rfq.productName, 'Cotton Wiping / Cleaning Rags');
      expect(rfq.quantity, '5000 kg');
      expect(rfq.destination, 'Jebel Ali, UAE');
      expect(rfq.status, RfqStatus.quoted);
      expect(rfq.submittedAt, DateTime.utc(2026, 9, 20, 10, 30));
      expect(rfq.assignee, 'Trade Desk');
      expect(rfq.nextStep, 'Review quotation');
    });

    test('unknown status keys fall back to a safe default', () {
      final dto = RfqDto.fromJson({
        'id': 'rfq_x',
        'status': 'something_new',
      });
      expect(dto.toEntity().status, RfqStatus.submitted);
    });

    test('missing optional fields do not throw', () {
      final dto = RfqDto.fromJson({'id': 'rfq_y'});
      final rfq = dto.toEntity();
      expect(rfq.productName, isEmpty);
      expect(rfq.assignee, isNull);
      expect(rfq.nextStep, isNull);
    });
  });
}
