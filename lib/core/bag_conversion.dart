import 'weight_math.dart';

/// Bao quy đổi là quy ước báo cáo (kg/bao), KHÔNG phải số bao thực tế nhập.
/// Mọi phép tính lưu bằng gram nguyên để tránh sai số dấu phẩy động.
class BagConversion {
  static const int defaultBagGrams = 50000; // Mặc định 50 kg/bao; chỉnh theo từng lô.

  static void validate(int bagGrams) {
    if (bagGrams <= 0 || bagGrams > 1000000) {
      throw const FormatException('Khối lượng quy đổi phải từ 0,01 đến 1.000 kg/bao.');
    }
  }

  static int wholeBags(int weightGrams, int bagGrams) {
    validate(bagGrams);
    if (weightGrams < 0) throw const FormatException('Không thể quy đổi kg âm.');
    return weightGrams ~/ bagGrams;
  }

  static int remainderGrams(int weightGrams, int bagGrams) {
    validate(bagGrams);
    if (weightGrams < 0) throw const FormatException('Không thể quy đổi kg âm.');
    return weightGrams % bagGrams;
  }

  /// Làm tròn half-up tới 2 chữ số lẻ để HIỂN THỊ số bao tương đương.
  static String equivalent(int weightGrams, int bagGrams) {
    validate(bagGrams);
    if (weightGrams < 0) throw const FormatException('Không thể quy đổi kg âm.');
    final hundredths = (weightGrams * 100 + bagGrams ~/ 2) ~/ bagGrams;
    return '${hundredths ~/ 100},${(hundredths % 100).toString().padLeft(2, '0')}';
  }

  static String breakdown(int weightGrams, int bagGrams, {int decimals = 2}) {
    return '${wholeBags(weightGrams, bagGrams)} bao + '
        '${WeightMath.weight(remainderGrams(weightGrams, bagGrams), decimals)} kg lẻ';
  }
}
