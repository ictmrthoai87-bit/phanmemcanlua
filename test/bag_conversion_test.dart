import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/core/bag_conversion.dart';
import 'package:lua_can_pro/models/weigh_models.dart';
import 'package:lua_can_pro/services/csv_service.dart';
import 'package:lua_can_pro/services/receipt_service.dart';

void main() {
  final time = DateTime.utc(2026, 10, 10, 1, 0);

  test('50 kg/bao: giữ số dư chính xác và làm tròn chỉ khi hiển thị', () {
    expect(BagConversion.wholeBags(125550, 50000), 2);
    expect(BagConversion.remainderGrams(125550, 50000), 25550);
    expect(BagConversion.equivalent(125550, 50000), '2,51');
    expect(BagConversion.breakdown(125550, 50000), '2 bao + 25,55 kg lẻ');
    expect(BagConversion.equivalent(0, 50000), '0,00');
  });

  test('Người dùng tự đổi kg/bao và phân biệt bao quy đổi - bao thực', () {
    expect(BagConversion.equivalent(100000, 40000), '2,50');
    expect(BagConversion.equivalent(100000, 60000), '1,67');
    expect(BagConversion.breakdown(100000, 60000), '1 bao + 40,00 kg lẻ');
    expect(() => BagConversion.equivalent(100000, 0), throwsFormatException);
    expect(() => BagConversion.equivalent(-1, 50000), throwsFormatException);
  });

  test('Theo bao: từng lượt tính trên kg thực; tổng không tính bì lần hai', () {
    final s = WeighSession(id: 'x', name: 'Lô x', customer: '',
      priceVnd: 6500, decimals: 2, createdAt: time,
      tareMode: TareMode.perBag, tarePerBagGrams: 500,
      equivalentBagGrams: 50000);
    final e = WeighEntry(id: 'e', sessionId: 'x', grossGrams: 125500,
      tareGrams: 1000, bagCount: 2, source: 'Nhập tay', note: '', createdAt: time);
    final total = WeighSummary.forSession(s, [e]);
    expect(total.gross, 125500);
    expect(total.tare, 1000);
    expect(total.net, 124500);
    expect(total.bags, 2);
    expect(BagConversion.equivalent(e.netGrams, s.equivalentBagGrams), '2,49');
    final csv = CsvService.build(s, [e]);
    expect(csv.contains('2,49'), isTrue);
    expect(csv.contains('124,50'), isTrue);
    final receipt = ReceiptService.build(s, [e]);
    expect(receipt.contains('BAO QUY ĐỔI: 2,49 bao'), isTrue);
  });

  test('Trừ cuối: bao lượt tạm tính theo kg cân, tổng theo kg thực', () {
    final s = WeighSession(id: 'y', name: 'Lô y', customer: '',
      priceVnd: 6500, decimals: 2, createdAt: time,
      tareMode: TareMode.afterTotal, finalTareGrams: 3500,
      equivalentBagGrams: 50000);
    final entries = [
      WeighEntry(id: 'e1', sessionId: 'y', grossGrams: 120000,
        tareGrams: 0, source: 'Nhập tay', note: '', createdAt: time),
      WeighEntry(id: 'e2', sessionId: 'y', grossGrams: 80000,
        tareGrams: 0, source: 'Nhập tay', note: '', createdAt: time),
    ];
    final total = WeighSummary.forSession(s, entries);
    expect(total.net, 196500);
    expect(BagConversion.equivalent(entries.first.grossGrams, s.equivalentBagGrams), '2,40');
    expect(BagConversion.equivalent(entries.last.grossGrams, s.equivalentBagGrams), '1,60');
    expect(BagConversion.equivalent(total.net, s.equivalentBagGrams), '3,93');
    final csv = CsvService.build(s, entries);
    expect(csv.contains('chưa phân bì cuối'), true);
    expect(csv.contains('3,93'), true);
  });

  test('Mở tệp sao lưu cũ: tự mặc định 50 kg/bao, không mất cấu hình mới', () {
    final old = WeighSession.fromMap({
      'id': 'z', 'name': 'Lô cũ', 'customer': '', 'price_vnd': 0,
      'decimals': 1, 'created_at': time.toIso8601String(),
    });
    expect(old.equivalentBagGrams, 50000);
    expect(old.copyWith(equivalentBagGrams: 45000).toMap()['equivalent_bag_grams'], 45000);
  });
}
