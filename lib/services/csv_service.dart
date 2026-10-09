import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/weight_math.dart';
import '../core/bag_conversion.dart';
import '../models/weigh_models.dart';

class CsvService {
  static String _field(String text) {
    // Protect spreadsheet viewers from formula injection.
    final escaped = RegExp(r'^[\s]*[=+@\-]').hasMatch(text) ? "'$text" : text;
    final quoted = escaped.replaceAll('"', '""');
    return '"$quoted"';
  }

  static String _line(List<String> values) => values.map(_field).join(';');

  static String build(WeighSession session, List<WeighEntry> entries) {
    final rows = <String>[
      _line(['PHẦN MỀM CÂN LÚA PRO', 'Báo cáo phiên cân']),
      _line(['Phiên cân', session.name]),
      _line(['Khách hàng', session.customer]),
      _line(['Giống lúa', session.variety]),
      _line(['Điện thoại', session.phone]),
      _line(['Đơn giá (VND/kg)', session.priceVnd.toString()]),
      _line(['Chế độ trừ bì', session.tareMode.label]),
      _line(['Kg trên 1 bao quy đổi', WeightMath.weight(session.equivalentBagGrams, 2)]),
      if (session.tareMode == TareMode.afterTotal && session.finalTareGrams == 0 && entries.isNotEmpty)
        _line(['TÌNH TRẠNG', 'CHƯA NHẬP BÌ CUỐI - SỐ TIỀN TẠM TÍNH']),
      _line(['Bì mặc định / bao (kg)', WeightMath.weight(session.tarePerBagGrams, session.decimals)]),
      _line(['Tổng bì cuối (kg)', WeightMath.weight(session.finalTareGrams, session.decimals)]),
      '',
      _line(['STT', 'Thời gian', 'Cân tổng (kg)', 'Bì lượt (kg)', 'Cân thực lượt (kg)',
        'Số bao thực', 'Kg dùng quy đổi (lượt)', 'Bao quy đổi (lượt)', 'Kg/bao quy đổi', 'Nguồn', 'Ghi chú']),
    ];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      rows.add(_line([
        '${i + 1}', e.createdAt.toLocal().toString(),
        WeightMath.weight(e.grossGrams, session.decimals),
        session.tareMode == TareMode.perBag
            ? WeightMath.weight(e.tareGrams, session.decimals) : '',
        session.tareMode == TareMode.perBag
            ? WeightMath.weight(e.netGrams, session.decimals) : '',
        e.bagCount > 0 ? '${e.bagCount}' : '',
        WeightMath.weight(session.tareMode == TareMode.perBag ? e.netGrams : e.grossGrams, session.decimals),
        BagConversion.equivalent(session.tareMode == TareMode.perBag ? e.netGrams : e.grossGrams, session.equivalentBagGrams),
        WeightMath.weight(session.equivalentBagGrams, 2),
        e.source, e.note,
      ]));
    }
    final summary = WeighSummary.forSession(session, entries);
    rows.add('');
    rows.add(_line(['SỐ LẦN CÂN', '${summary.count}']));
    rows.add(_line(['TỔNG CÂN (kg)', WeightMath.weight(summary.gross, session.decimals)]));
    if (session.tareMode == TareMode.perBag) {
      rows.add(_line(['TỔNG SỐ BAO', '${summary.bags}']));
    }
    rows.add(_line(['TỔNG BÌ (kg)', WeightMath.weight(summary.tare, session.decimals)]));
    rows.add(_line(['THỰC NHẬN (kg)', WeightMath.weight(summary.net, session.decimals)]));
    rows.add(_line(['TỔNG BAO QUY ĐỔI', BagConversion.equivalent(summary.net, session.equivalentBagGrams)]));
    rows.add(_line(['BAO TRÒN + KG LẺ', BagConversion.breakdown(summary.net, session.equivalentBagGrams, decimals: 2)]));
    if (session.tareMode == TareMode.afterTotal) {
      rows.add(_line(['Lưu ý', 'Bao quy đổi từng lượt tính từ cân tổng, chưa phân bì cuối; tổng bao quy đổi tính từ cân thực cuối lô.']));
    }
    rows.add(_line(['THÀNH TIỀN (VND)', '${summary.amount}']));
    rows.add(_line(['ĐÃ THANH TOÁN (VND)', '${session.paidVnd}']));
    rows.add(_line(['CÒN LẠI (VND)', '${summary.remaining(session.paidVnd)}']));
    rows.add(_line(['Cách tính', session.tareMode == TareMode.perBag
      ? 'Trừ bì theo từng lượt; tiền làm tròn một lần trên tổng thực nhận'
      : 'Trừ tổng bì một lần cuối; tiền làm tròn một lần trên tổng thực nhận']));
    return '\uFEFF${rows.join('\r\n')}\r\n';
  }

  Future<File> createFile(WeighSession session, List<WeighEntry> entries) async {
    final temp = await getTemporaryDirectory();
    final filename = 'can_lua_${session.createdAt.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${temp.path}${Platform.pathSeparator}$filename');
    return file.writeAsBytes(utf8.encode(build(session, entries)), flush: true);
  }
}
