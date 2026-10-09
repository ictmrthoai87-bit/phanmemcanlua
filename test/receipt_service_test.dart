import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/models/weigh_models.dart';
import 'package:lua_can_pro/services/receipt_service.dart';

void main() {
  final date = DateTime.utc(2026, 10, 9);
  final session = WeighSession(
    id: 'test', name: 'Lô 01', customer: 'Nguyễn Văn A', variety: 'OM 18',
    phone: '0900000000', priceVnd: 6500, decimals: 2,
    paidVnd: 3000000, createdAt: date,
  );
  final rows = <WeighEntry>[
    WeighEntry(id: 'one', sessionId: 'test', grossGrams: 501550,
      tareGrams: 1550, source: 'Nhập tay', note: '', createdAt: date),
    WeighEntry(id: 'two', sessionId: 'test', grossGrams: 350550,
      tareGrams: 20550, source: 'Nhập tay', note: '', createdAt: date),
  ];
  test('phiếu cân đúng tổng, công nợ và thông tin người bán', () {
    final r = ReceiptService.build(session, rows);
    expect(r.contains('LÚA THỰC: 830,00 kg'), isTrue);
    expect(r.contains('THÀNH TIỀN: 5.395.000 đ'), isTrue);
    expect(r.contains('CÒN LẠI: 2.395.000 đ'), isTrue);
    expect(r.contains('OM 18'), isTrue);
    expect(r.contains('0900000000'), isTrue);
  });
  test('phiếu thể hiện đã trả dư', () {
    final r = ReceiptService.build(session.copyWith(paidVnd: 5500000), rows);
    expect(r.contains('TRẢ DƯ: 105.000 đ'), isTrue);
  });
}
