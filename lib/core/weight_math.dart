/// Pure integer math: 1 kilogram = 1,000 grams. Monetary values are VND.
/// Never calculate settlements using double arithmetic.
class WeightMath {
  static int parseWeightGrams(String text, {required int decimals}) {
    if (decimals != 1 && decimals != 2) {
      throw const FormatException('Số chữ số lẻ phải bằng 1 hoặc 2.');
    }
    final cleaned = text.trim().replaceAll(' ', '');
    if (!RegExp(r'^\d{1,7}(?:[.,]\d{1,2})?$').hasMatch(cleaned)) {
      throw const FormatException('Khối lượng không hợp lệ (VD: 125,5 hoặc 125,55).');
    }
    final parts = cleaned.replaceAll(',', '.').split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    if (fraction.length > decimals) {
      throw FormatException('Chỉ cho phép $decimals chữ số lẻ.');
    }
    final kg = int.parse(parts[0]);
    final grams = kg * 1000 + int.parse(fraction.padRight(3, '0').isEmpty ? '0' : fraction.padRight(3, '0'));
    if (grams > 100000000) {
      throw const FormatException('Khối lượng vượt giới hạn 100.000 kg.');
    }
    return grams;
  }

  static int parsePriceVnd(String text) {
    final cleaned = text.trim();
    // A price is integer VND: accept 6500, 6.500, 6,500 or 6 500; reject 6500.5.
    if (cleaned.isEmpty || !RegExp(r'^(?:\d{1,12}|\d{1,3}(?:[., ]\d{3})+)$').hasMatch(cleaned)) {
      throw const FormatException('Đơn giá phải là số nguyên VND/kg.');
    }
    final digits = cleaned.replaceAll(RegExp(r'[\s.,]'), '');
    if (digits.length > 12) {
      throw const FormatException('Đơn giá vượt giới hạn.');
    }
    final value = int.parse(digits);
    if (value > 1000000000) {
      throw const FormatException('Đơn giá vượt giới hạn.');
    }
    return value;
  }

  /// Money amount received/paid, can be much larger than per-kg price.
  static int parseAmountVnd(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty ||
        !RegExp(r'^(?:\d{1,15}|\d{1,3}(?:[., ]\d{3})+)$').hasMatch(cleaned)) {
      throw const FormatException('Số tiền không hợp lệ (ví dụ: 3.000.000).');
    }
    final value = int.parse(cleaned.replaceAll(RegExp(r'[\s.,]'), ''));
    if (value > 100000000000000) {
      throw const FormatException('Số tiền vượt mức cho phép.');
    }
    return value;
  }

  static int parseBagCount(String text) {
    final cleaned = text.trim();
    if (!RegExp(r'^\d{1,5}$').hasMatch(cleaned)) {
      throw const FormatException('Số bao phải từ 1 đến 99.999.');
    }
    final count = int.parse(cleaned);
    if (count < 1 || count > 99999) {
      throw const FormatException('Số bao phải từ 1 đến 99.999.');
    }
    return count;
  }

  static int tareByBag(int tareEachGrams, int bags) {
    if (tareEachGrams < 0 || bags < 1 || bags > 99999) {
      throw const FormatException('Bì mỗi bao hoặc số bao không hợp lệ.');
    }
    return tareEachGrams * bags;
  }

  static String weight(int grams, int decimals) {
    if (decimals != 1 && decimals != 2) {
      throw ArgumentError('Invalid decimals: $decimals');
    }
    final factor = decimals == 1 ? 100 : 10;
    final scaled = (grams.abs() + factor ~/ 2) ~/ factor;
    final pow = decimals == 1 ? 10 : 100;
    final whole = scaled ~/ pow;
    final fraction = (scaled % pow).toString().padLeft(decimals, '0');
    return '${grams < 0 ? '-' : ''}$whole,$fraction';
  }

  static String money(int amount) {
    final digits = amount.abs().toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '${amount < 0 ? '-' : ''}$formatted';
  }

  static int netGrams(int grossGrams, int tareGrams) {
    if (grossGrams <= 0 || tareGrams < 0 || grossGrams <= tareGrams) {
      throw const FormatException('Số cân phải lớn hơn bì và lớn hơn 0.');
    }
    return grossGrams - tareGrams;
  }

  /// Rounds half up to whole VND: net grams * VND/kg / 1000.
  static int amountVnd(int netGrams, int priceVndPerKg) {
    if (netGrams < 0 || priceVndPerKg < 0) {
      throw ArgumentError('Net grams and price must be nonnegative.');
    }
    return (netGrams * priceVndPerKg + 500) ~/ 1000;
  }
}
