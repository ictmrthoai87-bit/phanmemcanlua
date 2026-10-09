import '../core/weight_math.dart';
import '../core/bag_conversion.dart';
import '../models/weigh_models.dart';

/// Readable plain-text receipt for sharing via Zalo/SMS/other apps.
/// Preview/print is NOT a legally certified electronic invoice.
class ReceiptService {
  static String date(DateTime value) {
    final d = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  static String build(WeighSession session, List<WeighEntry> entries) {
    final total = WeighSummary.forSession(session, entries);
    final lines = <String>[
      'PHIẾU CÂN LÚA - CÂN LÚA PRO',
      '--------------------------------',
      'Lô: ${session.name}',
      'Khách hàng: ${session.customer.isEmpty ? 'Chưa nhập' : session.customer}',
      if (session.phone.isNotEmpty) 'Điện thoại: ${session.phone}',
      if (session.variety.isNotEmpty) 'Giống lúa: ${session.variety}',
      'Ngày lập: ${date(session.createdAt)}',
      'Cách trừ bì: ${session.tareMode.label}',
      'Quy ước bao quy đổi: ${WeightMath.weight(session.equivalentBagGrams, 2)} kg/bao',
      if (session.tareMode == TareMode.afterTotal && session.finalTareGrams == 0 && entries.isNotEmpty)
        'CHƯA NHẬP BÌ CUỐI — SỐ TIỀN ĐANG TẠM TÍNH',
      if (session.tareMode == TareMode.perBag)
        'Bì mặc định của lượt mới: ${WeightMath.weight(session.tarePerBagGrams, session.decimals)} kg/bao',
      '--------------------------------',
    ];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (session.tareMode == TareMode.perBag) {
        lines.add('Lượt ${i + 1}: ${WeightMath.weight(e.grossGrams, session.decimals)} - '
            '${WeightMath.weight(e.tareGrams, session.decimals)} = '
            '${WeightMath.weight(e.netGrams, session.decimals)} kg'
            '${e.bagCount > 0 ? ' • ${e.bagCount} bao thực' : ''}'
            ' • ${BagConversion.equivalent(e.netGrams, session.equivalentBagGrams)} bao quy đổi');
      } else {
        lines.add('Lượt ${i + 1}: ${WeightMath.weight(e.grossGrams, session.decimals)} kg'
            ' (chưa trừ bì)'
            ' • ${BagConversion.equivalent(e.grossGrams, session.equivalentBagGrams)} bao tạm tính');
      }
    }
    lines.addAll([
      '--------------------------------',
      'Số lượt: ${total.count}',
      'Tổng cân: ${WeightMath.weight(total.gross, session.decimals)} kg',
      if (session.tareMode == TareMode.perBag)
        'Tổng số bao đã nhập: ${total.bags}',
      'Tổng bì (${session.tareMode == TareMode.perBag ? 'theo lượt' : 'trừ 1 lần cuối'}): '
          '${WeightMath.weight(total.tare, session.decimals)} kg',
      'LÚA THỰC: ${WeightMath.weight(total.net, session.decimals)} kg',
      'BAO QUY ĐỔI: ${BagConversion.equivalent(total.net, session.equivalentBagGrams)} bao',
      '(${BagConversion.breakdown(total.net, session.equivalentBagGrams, decimals: 2)})',
      'Đơn giá: ${WeightMath.money(session.priceVnd)} đ/kg',
      'THÀNH TIỀN: ${WeightMath.money(total.amount)} đ',
      'Đã thanh toán: ${WeightMath.money(session.paidVnd)} đ',
      if (total.remaining(session.paidVnd) >= 0)
        'CÒN LẠI: ${WeightMath.money(total.remaining(session.paidVnd))} đ'
      else
        'TRẢ DƯ: ${WeightMath.money(-total.remaining(session.paidVnd))} đ',
      '--------------------------------',
      'Vui lòng đối chiếu số cân trước khi chốt giao dịch.',
      'Phiếu thông tin; không thay thế hóa đơn điện tử.',
    ]);
    return lines.join('\n');
  }
}
