import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/models/weigh_models.dart';
import 'package:lua_can_pro/services/csv_service.dart';

void main() {
  final date = DateTime.utc(2026, 10, 9);
  final session = WeighSession(id: 'a', name: 'Lô số 1', customer: '=HYPERLINK("evil")',
    priceVnd: 6500, decimals: 2, createdAt: date);
  final weights = [
    WeighEntry(id: 'b', sessionId: 'a', grossGrams: 500550, tareGrams: 10550,
      source: 'Nhập tay', note: '+SUM(1,2)', createdAt: date),
    WeighEntry(id: 'c', sessionId: 'a', grossGrams: 350450, tareGrams: 10450,
      source: 'Nhập tay', note: 'OK', createdAt: date),
  ];
  test('tính tổng, bì, thực nhận chính xác', () {
    final s = WeighSummary(weights, 6500);
    expect(s.count, 2);
    expect(s.gross, 851000);
    expect(s.tare, 21000);
    expect(s.net, 830000);
    expect(s.amount, 5395000);
  });
  test('CSV BOM Excel, chống formula injection, dữ liệu khớp', () {
    final csv = CsvService.build(session, weights);
    expect(csv.startsWith('\uFEFF'), true);
    expect(csv.contains("'=HYPERLINK"), true);
    expect(csv.contains("'+SUM"), true);
    expect(csv.contains('830,00'), true);
    expect(csv.contains('5395000'), true);
  });
}
