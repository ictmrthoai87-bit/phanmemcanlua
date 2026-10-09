import '../core/weight_math.dart';
import '../core/bag_conversion.dart';

/// A session chooses EXACTLY ONE tare method. Persist the string values in SQLite.
enum TareMode {
  perBag('per_bag'),
  afterTotal('after_total');

  const TareMode(this.dbValue);
  final String dbValue;

  String get label => this == TareMode.perBag ? 'Theo đầu bao' : 'Trừ sau khi cân';

  static TareMode parse(Object? value) {
    if (value == null) return TareMode.perBag; // Pre-v0.5 sessions
    for (final mode in TareMode.values) {
      if (mode.dbValue == value) return mode;
    }
    throw const FormatException('Chế độ trừ bì trong dữ liệu không hợp lệ.');
  }
}

class WeighSession {
  const WeighSession({
    required this.id,
    required this.name,
    required this.customer,
    required this.priceVnd,
    required this.decimals,
    required this.createdAt,
    this.variety = '',
    this.phone = '',
    this.paidVnd = 0,
    this.tareMode = TareMode.perBag,
    this.tarePerBagGrams = 0,
    this.finalTareGrams = 0,
    this.equivalentBagGrams = BagConversion.defaultBagGrams,
  });

  final String id;
  final String name;
  final String customer;
  final int priceVnd;
  final int decimals;
  final DateTime createdAt;
  final String variety;
  final String phone;
  final int paidVnd;
  final TareMode tareMode;
  final int tarePerBagGrams;
  final int finalTareGrams;
  /// Kg quy đổi/bao; khác số bao thực tế có bì.
  final int equivalentBagGrams;

  WeighSession copyWith({String? name, String? customer, int? priceVnd,
    int? decimals, String? variety, String? phone, int? paidVnd,
    TareMode? tareMode, int? tarePerBagGrams, int? finalTareGrams,
    int? equivalentBagGrams}) => WeighSession(
    id: id, name: name ?? this.name, customer: customer ?? this.customer,
    priceVnd: priceVnd ?? this.priceVnd, decimals: decimals ?? this.decimals,
    createdAt: createdAt, variety: variety ?? this.variety,
    phone: phone ?? this.phone, paidVnd: paidVnd ?? this.paidVnd,
    tareMode: tareMode ?? this.tareMode,
    tarePerBagGrams: tarePerBagGrams ?? this.tarePerBagGrams,
    finalTareGrams: finalTareGrams ?? this.finalTareGrams,
    equivalentBagGrams: equivalentBagGrams ?? this.equivalentBagGrams,
  );

  factory WeighSession.fromMap(Map<String, Object?> m) => WeighSession(
    id: m['id'] as String, name: m['name'] as String,
    customer: m['customer'] as String, priceVnd: m['price_vnd'] as int,
    decimals: m['decimals'] as int,
    createdAt: DateTime.parse(m['created_at'] as String),
    variety: (m['variety'] as String?) ?? '',
    phone: (m['phone'] as String?) ?? '',
    paidVnd: (m['paid_vnd'] as int?) ?? 0,
    tareMode: TareMode.parse(m['tare_mode']),
    tarePerBagGrams: (m['tare_per_bag_grams'] as int?) ?? 0,
    finalTareGrams: (m['final_tare_grams'] as int?) ?? 0,
    equivalentBagGrams: (m['equivalent_bag_grams'] as int?) ?? BagConversion.defaultBagGrams,
  );

  Map<String, Object?> toMap() => {
    'id': id, 'name': name, 'customer': customer, 'price_vnd': priceVnd,
    'decimals': decimals, 'created_at': createdAt.toIso8601String(),
    'variety': variety, 'phone': phone, 'paid_vnd': paidVnd,
    'tare_mode': tareMode.dbValue,
    'tare_per_bag_grams': tarePerBagGrams,
    'final_tare_grams': finalTareGrams,
    'equivalent_bag_grams': equivalentBagGrams,
  };
}

class WeighEntry {
  const WeighEntry({required this.id, required this.sessionId,
    required this.grossGrams, required this.tareGrams, required this.source,
    required this.note, required this.createdAt, this.bagCount = 0});
  final String id;
  final String sessionId;
  final int grossGrams;
  /// Per-entry tare for perBag only. Always zero for afterTotal.
  final int tareGrams;
  final int bagCount;
  final String source;
  final String note;
  final DateTime createdAt;

  int get netGrams => grossGrams - tareGrams;
  int amountVnd(int price) => WeightMath.amountVnd(netGrams, price);

  WeighEntry copyWith({int? grossGrams, int? tareGrams, int? bagCount,
    String? note}) => WeighEntry(
    id: id, sessionId: sessionId, grossGrams: grossGrams ?? this.grossGrams,
    tareGrams: tareGrams ?? this.tareGrams, bagCount: bagCount ?? this.bagCount,
    source: source, note: note ?? this.note, createdAt: createdAt,
  );

  factory WeighEntry.fromMap(Map<String, Object?> m) => WeighEntry(
    id: m['id'] as String, sessionId: m['session_id'] as String,
    grossGrams: m['gross_grams'] as int, tareGrams: m['tare_grams'] as int,
    bagCount: (m['bag_count'] as int?) ?? 0,
    source: m['source'] as String, note: m['note'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  Map<String, Object?> toMap() => {
    'id': id, 'session_id': sessionId, 'gross_grams': grossGrams,
    'tare_grams': tareGrams, 'bag_count': bagCount, 'source': source,
    'note': note, 'created_at': createdAt.toIso8601String(),
  };
}

class WeighSummary {
  WeighSummary(this.entries, this.priceVnd, {
    this.tareMode = TareMode.perBag, this.finalTareGrams = 0,
  });
  final List<WeighEntry> entries;
  final int priceVnd;
  final TareMode tareMode;
  final int finalTareGrams;
  int get count => entries.length;
  int get gross => entries.fold<int>(0, (sum, e) => sum + e.grossGrams);
  int get bags => entries.fold<int>(0, (sum, e) => sum + e.bagCount);
  int get tare => tareMode == TareMode.afterTotal
      ? finalTareGrams : entries.fold<int>(0, (sum, e) => sum + e.tareGrams);
  int get net {
    if (tare < 0 || tare > gross) {
      throw const FormatException('Tổng bì lớn hơn tổng số cân. Vui lòng kiểm tra.');
    }
    return gross - tare;
  }
  int get amount => WeightMath.amountVnd(net, priceVnd);
  int remaining(int paidVnd) => amount - paidVnd;

  factory WeighSummary.forSession(WeighSession session, List<WeighEntry> entries) =>
      WeighSummary(entries, session.priceVnd,
        tareMode: session.tareMode, finalTareGrams: session.finalTareGrams);
}
