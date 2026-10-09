import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/models/weigh_models.dart';

void main() {
  test('đọc lại phiên v1 không mất tương thích', () {
    final s = WeighSession.fromMap({
      'id': '1', 'name': 'Lô cũ', 'customer': '', 'price_vnd': 6500,
      'decimals': 1, 'created_at': '2026-10-01T00:00:00',
    });
    expect(s.variety, '');
    expect(s.paidVnd, 0);
    expect(s.toMap()['price_vnd'], 6500);
  });
  test('sửa phiên không thay đổi ID và tiền đã trả', () {
    final initial = WeighSession(id: 's', name: 'Lô', customer: '',
      priceVnd: 6500, decimals: 1, paidVnd: 100000,
      createdAt: DateTime.utc(2026, 10, 1));
    final changed = initial.copyWith(customer: 'B', priceVnd: 7000);
    expect(changed.id, 's');
    expect(changed.paidVnd, 100000);
    expect(changed.priceVnd, 7000);
  });
}
