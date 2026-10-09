import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/core/weight_math.dart';

void main() {
  group('Khối lượng', () {
    test('1 chữ số lẻ chấp nhận dấu chấm và phẩy', () {
      expect(WeightMath.parseWeightGrams('125,5', decimals: 1), 125500);
      expect(WeightMath.parseWeightGrams('125.5', decimals: 1), 125500);
      expect(WeightMath.parseWeightGrams('125', decimals: 1), 125000);
      expect(WeightMath.weight(125500, 1), '125,5');
    });
    test('2 chữ số lẻ lưu chính xác đến 10 g', () {
      expect(WeightMath.parseWeightGrams('125,55', decimals: 2), 125550);
      expect(WeightMath.weight(125550, 2), '125,55');
      expect(WeightMath.parseWeightGrams('1,05', decimals: 2), 1050);
    });
    test('chặn quá số lẻ và âm', () {
      expect(() => WeightMath.parseWeightGrams('125,55', decimals: 1), throwsFormatException);
      expect(() => WeightMath.parseWeightGrams('-12,5', decimals: 2), throwsFormatException);
      expect(() => WeightMath.parseWeightGrams('12,555', decimals: 2), throwsFormatException);
    });
    test('trừ bì và từ chối bì lớn hơn cân', () {
      expect(WeightMath.netGrams(500500, 20000), 480500);
      expect(() => WeightMath.netGrams(500000, 500000), throwsFormatException);
      expect(() => WeightMath.netGrams(300000, 500000), throwsFormatException);
    });
  });
  group('Thanh toán', () {
    test('nhập giá có ngăn cách hàng nghìn', () {
      expect(WeightMath.parsePriceVnd('6.500'), 6500);
      expect(WeightMath.parsePriceVnd('6500'), 6500);
      expect(WeightMath.money(12345000), '12.345.000');
      expect(WeightMath.parseAmountVnd('1.250.000.000'), 1250000000);
    });
    test('không diễn giải giá thập phân sai', () {
      expect(() => WeightMath.parsePriceVnd('6500.5'), throwsFormatException);
    });
    test('tính tiền số nguyên và làm tròn', () {
      expect(WeightMath.amountVnd(100500, 6500), 653250);
      expect(WeightMath.amountVnd(10, 55), 1);
      expect(WeightMath.amountVnd(10, 45), 0);
    });
  });
}
