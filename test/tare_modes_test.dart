import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/core/weight_math.dart';
import 'package:lua_can_pro/models/weigh_models.dart';
import 'package:lua_can_pro/services/receipt_service.dart';
import 'package:lua_can_pro/services/csv_service.dart';

void main() {
  final date = DateTime.utc(2026, 10, 9);

  test('đầu bao: bì mỗi bao x số bao; làm tròn tiền một lần', () {
    final tare1 = WeightMath.tareByBag(
      WeightMath.parseWeightGrams('0,5', decimals: 1),
      WeightMath.parseBagCount('5'),
    );
    final tare2 = WeightMath.tareByBag(500, 2);
    expect(tare1, 2500);
    expect(tare2, 1000);
    final s = WeighSession(id: 'p', name: 'Lô đầu bao', customer: '',
      priceVnd: 6500, decimals: 1, createdAt: date,
      tareMode: TareMode.perBag, tarePerBagGrams: 500);
    final entries = [
      WeighEntry(id: 'a', sessionId: s.id, grossGrams: 500000,
        tareGrams: tare1, bagCount: 5, source: 'Nhập tay', note: '', createdAt: date),
      WeighEntry(id: 'b', sessionId: s.id, grossGrams: 300000,
        tareGrams: tare2, bagCount: 2, source: 'Nhập tay', note: '', createdAt: date),
    ];
    final sum = WeighSummary.forSession(s, entries);
    expect(sum.count, 2);
    expect(sum.bags, 7);
    expect(sum.gross, 800000);
    expect(sum.tare, 3500);
    expect(sum.net, 796500);
    expect(sum.amount, 5177250);
    expect(ReceiptService.build(s, entries), contains('Tổng số bao đã nhập: 7'));
    expect(CsvService.build(s, entries), contains('5177250'));
  });

  test('trừ sau: không bớt ở từng lượt, chỉ trừ tổng bì một lần', () {
    final s = WeighSession(id: 'l', name: 'Lô trừ cuối', customer: '',
      priceVnd: 6500, decimals: 1, createdAt: date,
      tareMode: TareMode.afterTotal, finalTareGrams: 3500);
    final entries = [
      WeighEntry(id: 'a', sessionId: s.id, grossGrams: 500000,
        tareGrams: 0, source: 'Nhập tay', note: '', createdAt: date),
      WeighEntry(id: 'b', sessionId: s.id, grossGrams: 300000,
        tareGrams: 0, source: 'Nhập tay', note: '', createdAt: date),
    ];
    final sum = WeighSummary.forSession(s, entries);
    expect(sum.gross, 800000);
    expect(sum.tare, 3500);
    expect(sum.net, 796500);
    expect(sum.amount, 5177250);
    final receipt = ReceiptService.build(s, entries);
    expect(receipt, contains('trừ 1 lần cuối'));
    expect(receipt, contains('Lượt 1: 500,0 kg (chưa trừ bì)'));
    final csv = CsvService.build(s, entries);
    expect(csv, contains('Trừ sau khi cân'));
    expect(csv, contains('796,5'));
  });

  test('bì/bao hai số lẻ, không dùng số thực', () {
    final perBag = WeightMath.parseWeightGrams('0,25', decimals: 2);
    expect(WeightMath.tareByBag(perBag, WeightMath.parseBagCount('5')), 1250);
    expect(WeightMath.weight(1250, 2), '1,25');
  });

  test('chặn số bao không hợp lệ và tổng bì âm/lớn hơn tổng cân', () {
    expect(() => WeightMath.parseBagCount('0'), throwsFormatException);
    expect(() => WeightMath.parseBagCount('100000'), throwsFormatException);
    expect(() => WeightMath.parseBagCount('2,5'), throwsFormatException);
    expect(() => WeightMath.tareByBag(-100, 3), throwsFormatException);
    final e = WeighEntry(id: 'e', sessionId: 's', grossGrams: 100000,
      tareGrams: 0, source: 'Nhập tay', note: '', createdAt: date);
    expect(() => WeighSummary([e], 7000,
      tareMode: TareMode.afterTotal, finalTareGrams: 101000).net,
      throwsFormatException);
  });

  test('phiên/lượt từ bản cũ vẫn mở được, mặc định không tự trừ bì cuối', () {
    final old = WeighSession.fromMap({
      'id': 'old', 'name': 'Lô cũ', 'customer': '', 'price_vnd': 6500,
      'decimals': 1, 'created_at': date.toIso8601String(),
    });
    final weight = WeighEntry.fromMap({
      'id': 'old-e', 'session_id': 'old', 'gross_grams': 500000,
      'tare_grams': 2500, 'source': 'Nhập tay', 'note': '',
      'created_at': date.toIso8601String(),
    });
    expect(old.tareMode, TareMode.perBag);
    expect(old.finalTareGrams, 0);
    expect(weight.bagCount, 0);
    expect(WeighSummary.forSession(old, [weight]).net, 497500);
  });
}
