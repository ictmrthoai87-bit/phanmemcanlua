import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_info.dart';
import '../core/weight_math.dart';
import '../core/bag_conversion.dart';
import '../core/share_sheet_origin.dart';
import '../data/local_database.dart';
import '../models/weigh_models.dart';
import '../services/backup_service.dart';
import '../services/csv_service.dart';
import '../services/id_factory.dart';
import '../services/receipt_service.dart';

const _green = Color(0xFF176846);
const _dark = Color(0xFF183729);
const _surface = Color(0xFFF3F7F1);

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});
  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final _store = LocalDatabase();
  final _backup = BackupService();
  final _csv = CsvService();
  final _gross = TextEditingController();
  final _grossFocus = FocusNode();
  final _finalTare = TextEditingController(text: '0');
  final _bags = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _note = TextEditingController();
  final _search = TextEditingController();

  List<WeighSession> _sessions = [];
  List<WeighEntry> _entries = [];
  WeighSession? _active;
  bool _busy = true;
  bool _showEntryNote = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
    for (final c in [_gross, _bags, _finalTare]) {
      c.addListener(_previewChanged);
    }
    _search.addListener(_previewChanged);
  }

  void _previewChanged() { if (mounted) setState(() {}); }

  void _switchTab(int value) {
    _grossFocus.unfocus();
    setState(() => _tab = value);
  }

  @override
  void dispose() {
    for (final c in [_gross, _bags, _finalTare, _price, _note, _search]) {
      c.dispose();
    }
    _grossFocus.dispose();
    _store.close();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating, content: Text(message),
    ));
  }

  void _error(Object e) => _toast(e is FormatException ? e.message : 'Thao tác thất bại. Vui lòng thử lại.');

  Future<void> _load({String? selectId}) async {
    try {
      var sessions = await _store.sessions();
      if (sessions.isEmpty) {
        final now = DateTime.now();
        await _store.upsertSession(WeighSession(
          id: IdFactory.next(), name: 'Lô lúa ${now.day}/${now.month}',
          customer: '', priceVnd: 0, decimals: 1, createdAt: now,
        ));
        sessions = await _store.sessions();
      }
      final wanted = selectId ?? _active?.id;
      final index = sessions.indexWhere((session) => session.id == wanted);
      final active = sessions[index < 0 ? 0 : index];
      final entries = await _store.entries(active.id);
      if (!mounted) return;
      _price.text = active.priceVnd == 0 ? '' : '${active.priceVnd}';
      _finalTare.text = WeightMath.weight(active.finalTareGrams, active.decimals);
      setState(() {
        _sessions = sessions;
        _entries = entries;
        _active = active;
        _busy = false;
      });
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      _error(e);
    }
  }

  Future<void> _refresh() => _load(selectId: _active?.id);

  int _currentTare(WeighSession session) {
    if (session.tareMode == TareMode.afterTotal) return 0;
    final bags = WeightMath.parseBagCount(_bags.text);
    return WeightMath.tareByBag(session.tarePerBagGrams, bags);
  }

  String? _preview() {
    final session = _active;
    if (session == null || _gross.text.trim().isEmpty) return null;
    try {
      final gross = WeightMath.parseWeightGrams(_gross.text, decimals: session.decimals);
      if (session.tareMode == TareMode.afterTotal) {
        return 'Sẽ cộng ${WeightMath.weight(gross, session.decimals)} kg vào tổng. Bì sẽ trừ cuối.';
      }
      final tare = _currentTare(session);
      final net = WeightMath.netGrams(gross, tare);
      return 'Trừ ${WeightMath.weight(tare, session.decimals)} kg bì → '
          'Còn ${WeightMath.weight(net, session.decimals)} kg';
    } catch (_) {
      return 'Kiểm tra lại số cân, số bao và mức bì.';
    }
  }

  /// Tare method applies to the whole lot. No retroactive rebilling of existing weights.
  Future<void> _tareSettings() async {
    final s = _active;
    if (s == null) return;
    var mode = s.tareMode;
    var perBagText = WeightMath.weight(s.tarePerBagGrams, s.decimals);
    var finalTareText = WeightMath.weight(s.finalTareGrams, s.decimals);
    final canChangeMode = _entries.isEmpty;
    final saved = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => AlertDialog(
        title: const Text('CẤU HÌNH CÁCH TRỪ BÌ'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn 1 trong 2 cách tính cho lô này:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<TareMode>(
              segments: const [
                ButtonSegment(value: TareMode.perBag, label: Text('Theo đầu bao')),
                ButtonSegment(value: TareMode.afterTotal, label: Text('Trừ cuối')),
              ],
              selected: {mode},
              onSelectionChanged: canChangeMode
                  ? (v) => update(() => mode = v.first) : null,
            ),
            const SizedBox(height: 7),
            Text(mode == TareMode.perBag
              ? 'Mỗi lượt nhập số bao. Bì = số bao × kg bì/bao.'
              : 'Cộng toàn bộ số cân, sau đó nhập tổng kg bì đúng một lần.'),
            if (!canChangeMode)
              const Text('Đã có lượt cân: không thể đổi phương pháp để tránh trừ bì 2 lần. '
                  'Bạn vẫn có thể điều chỉnh mức bì. Muốn đổi phương pháp, hãy tạo lô mới.',
                  style: TextStyle(color: Color(0xFF9C5C0C))),
            const SizedBox(height: 16),
            if (mode == TareMode.perBag) ...[
              TextFormField(key: const ValueKey('config_per_bag'), initialValue: perBagText,
                onChanged: (v) => perBagText = v,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Bì 1 bao (kg)',
                  helperText: 'Mức mới chỉ áp dụng các lượt cân tiếp theo.')),
            ] else ...[
              TextFormField(key: const ValueKey('config_after_total'), initialValue: finalTareText,
                onChanged: (v) => finalTareText = v,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tổng bì trừ cuối (kg)',
                  helperText: 'Có thể để 0 và nhập sau khi cân xong.')),
            ],
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('LƯU CẤU HÌNH')),
        ],
      ),
    ));
    if (saved != true) return;
    try {
      if (!canChangeMode && mode != s.tareMode) {
        throw const FormatException('Không thể đổi chế độ khi lô đã có lượt cân.');
      }
      final perBag = mode == TareMode.perBag
          ? WeightMath.parseWeightGrams(perBagText, decimals: s.decimals)
          : s.tarePerBagGrams;
      final finalTare = mode == TareMode.afterTotal
          ? WeightMath.parseWeightGrams(finalTareText, decimals: s.decimals)
          : 0;
      final gross = _entries.fold<int>(0, (sum, e) => sum + e.grossGrams);
      if (mode == TareMode.afterTotal && finalTare != 0 &&
          (gross == 0 || finalTare >= gross)) {
        throw const FormatException('Tổng bì trừ cuối phải nhỏ hơn tổng cân.');
      }
      await _store.upsertSession(s.copyWith(tareMode: mode,
        tarePerBagGrams: perBag, finalTareGrams: finalTare));
      await _refresh();
      _toast('Đã lưu chế độ ${mode.label.toLowerCase()}.');
    } catch (e) { _error(e); }
  }

  /// kg/bao quy đổi để xem báo cáo, KHÔNG dùng để tính bì.
  Future<void> _bagConversionSettings() async {
    final s = _active;
    if (s == null) return;
    var weight = WeightMath.weight(s.equivalentBagGrams, 2);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('CẤU HÌNH BAO QUY ĐỔI'),
      content: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mặc định 50 kg/bao. Có thể đổi 40 kg, 45 kg, 50 kg, 60 kg... cho từng lô.'),
          const SizedBox(height: 12),
          TextFormField(initialValue: weight, onChanged: (v) => weight = v,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Số kg quy đổi cho 1 bao'),
          ),
          const SizedBox(height: 10),
          const Text('Đây là bao tương đương theo khối lượng; KHÁC số bao thực nhập khi trừ bì.',
            style: TextStyle(color: Color(0xFF865C11))),
        ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('LƯU')),
      ],
    ));
    if (ok != true) return;
    try {
      final grams = WeightMath.parseWeightGrams(weight, decimals: 2);
      BagConversion.validate(grams);
      await _store.upsertSession(s.copyWith(equivalentBagGrams: grams));
      await _refresh();
      _toast('Đã chọn ${WeightMath.weight(grams, 2)} kg/bao quy đổi.');
    } catch (e) { _error(e); }
  }

  Future<void> _saveFinalTare() async {
    final s = _active;
    if (s == null || s.tareMode != TareMode.afterTotal) return;
    try {
      final tare = WeightMath.parseWeightGrams(_finalTare.text, decimals: s.decimals);
      final gross = _entries.fold<int>(0, (sum, e) => sum + e.grossGrams);
      if (tare != 0 && (gross == 0 || tare >= gross)) {
        throw const FormatException('Tổng bì cuối phải nhỏ hơn tổng kg đã cân.');
      }
      await _store.upsertSession(s.copyWith(finalTareGrams: tare));
      await _refresh();
      _toast('Đã cập nhật tổng bì cuối và tính lại số tiền.');
    } catch (e) { _error(e); }
  }

  Future<void> _savePrice() async {
    final s = _active;
    if (s == null) return;
    try {
      final value = WeightMath.parsePriceVnd(_price.text);
      await _store.upsertSession(s.copyWith(priceVnd: value));
      await _refresh();
      _toast('Đã lưu giá lúa: ${WeightMath.money(value)} đ/kg.');
    } catch (e) { _error(e); }
  }

  Future<void> _changeDecimals(int value) async {
    final s = _active;
    if (s == null || value == s.decimals) return;
    if (value == 1 && (_entries.any((e) =>
        e.grossGrams % 100 != 0 || e.tareGrams % 100 != 0) ||
        s.tarePerBagGrams % 100 != 0 || s.finalTareGrams % 100 != 0)) {
      _toast('Đã có cân 2 số lẻ. Không thể đổi về 1 số lẻ.');
      return;
    }
    try {
      await _store.upsertSession(s.copyWith(decimals: value));
      await _refresh();
    } catch (e) { _error(e); }
  }

  Future<void> _addManual() async {
    final s = _active;
    if (s == null || _busy) return;
    setState(() => _busy = true);
    try {
      final gross = WeightMath.parseWeightGrams(_gross.text, decimals: s.decimals);
      final tare = _currentTare(s);
      WeightMath.netGrams(gross, tare);
      final bags = s.tareMode == TareMode.perBag
          ? WeightMath.parseBagCount(_bags.text) : 0;
      final duplicate = _entries.any((e) =>
          e.grossGrams == gross && e.tareGrams == tare && e.bagCount == bags &&
          DateTime.now().difference(e.createdAt).inSeconds.abs() < 90);
      if (duplicate && !await _confirm('Có thể đã nhập trùng',
          'Vừa có một lượt cân cùng số kg và cùng bì trong 90 giây. Vẫn thêm lần này?',
          action: 'Vẫn thêm')) {
        return;
      }
      final e = WeighEntry(id: IdFactory.next(), sessionId: s.id,
          grossGrams: gross, tareGrams: tare, bagCount: bags, source: 'Nhập tay',
          note: _note.text.trim(), createdAt: DateTime.now());
      await _store.insertEntries([e]);
      _gross.clear();
      _note.clear();
      _showEntryNote = false;
      await _refresh();
      _toast('Đã lưu lượt ${_entries.length}. Tổng: ${WeightMath.weight(WeighSummary.forSession(s, _entries).net, s.decimals)} kg.');
      // Giữ người dùng ở ô cân để cân lượt tiếp theo nhanh nhất.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _grossFocus.requestFocus();
      });
    } catch (e) { _error(e); }
      finally { if (mounted) setState(() => _busy = false); }
  }

  Future<bool> _confirm(String title, String description, {String action = 'Đồng ý'}) async =>
      await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text(title), content: Text(description), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ])) ?? false;

  Future<void> _sessionDialog({WeighSession? existing}) async {
    final now = DateTime.now();
    var name = existing?.name ?? 'Lô lúa ${now.day}/${now.month}';
    var customer = existing?.customer ?? '';
    var variety = existing?.variety ?? '';
    var phone = existing?.phone ?? '';
    final decimals = existing?.decimals ?? _active?.decimals ?? 1;
    final tareMode = existing?.tareMode ?? _active?.tareMode ?? TareMode.perBag;
    final saved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tạo lô cân mới' : 'Sửa thông tin lô'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(initialValue: name, onChanged: (v) => name = v,
              decoration: const InputDecoration(labelText: 'Tên lô hoặc chuyến lúa *')),
            const SizedBox(height: 12),
            TextFormField(initialValue: customer, onChanged: (v) => customer = v,
              decoration: const InputDecoration(labelText: 'Tên người bán/mua')),
            const SizedBox(height: 12),
            TextFormField(initialValue: variety, onChanged: (v) => variety = v,
              decoration: const InputDecoration(labelText: 'Giống lúa (tùy chọn)')),
            const SizedBox(height: 12),
            TextFormField(initialValue: phone, onChanged: (v) => phone = v,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại (tùy chọn)')),
            const SizedBox(height: 12),
            const Text('Đơn giá, số lẻ, trừ bì và quy đổi bao được thiết lập tại tab CẤU HÌNH.',
              style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu lô')),
        ],
      ));
    if (saved != true) return;
    try {
      if (name.trim().isEmpty) throw const FormatException('Vui lòng nhập tên lô.');
      if (name.length > 120 || customer.length > 120 || variety.length > 120 || phone.length > 40) {
        throw const FormatException('Nội dung nhập quá dài.');
      }
      final price = existing?.priceVnd ?? _active?.priceVnd ?? 0;
      final updated = WeighSession(id: existing?.id ?? IdFactory.next(),
        name: name.trim(), customer: customer.trim(), variety: variety.trim(),
        phone: phone.trim(), priceVnd: price, decimals: decimals,
        createdAt: existing?.createdAt ?? now, paidVnd: existing?.paidVnd ?? 0,
        tareMode: tareMode, tarePerBagGrams: existing?.tarePerBagGrams ??
          (tareMode == TareMode.perBag ? (_active?.tarePerBagGrams ?? 0) : 0),
        finalTareGrams: existing?.finalTareGrams ?? 0,
        equivalentBagGrams: existing?.equivalentBagGrams ??
          _active?.equivalentBagGrams ?? BagConversion.defaultBagGrams);
      await _store.upsertSession(updated);
      _gross.clear(); _note.clear();
      await _load(selectId: updated.id);
      if (mounted) setState(() => _tab = 0);
      _toast(existing == null ? 'Đã tạo lô cân mới.' : 'Đã cập nhật thông tin lô.');
    } catch (e) { _error(e); }
  }

  Future<void> _paidDialog() async {
    final s = _active;
    if (s == null) return;
    var text = '${s.paidVnd}';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tiền đã thanh toán'),
      content: TextFormField(initialValue: text, onChanged: (v) => text = v,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Tổng số tiền đã trả (đồng)',
            helperText: 'Có thể nhập trước tiền cọc; số còn lại tự tính')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
      ],
    ));
    if (ok != true) return;
    try {
      final amount = WeightMath.parseAmountVnd(text);
      await _store.upsertSession(s.copyWith(paidVnd: amount));
      await _refresh();
    } catch (e) { _error(e); }
  }

  Future<void> _editEntry(WeighEntry e) async {
    final session = _active;
    if (session == null) return;
    var grossText = WeightMath.weight(e.grossGrams, session.decimals);
    var tareText = WeightMath.weight(e.tareGrams, session.decimals);
    var bagText = '${e.bagCount}';
    var note = e.note;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Sửa lượt cân'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(initialValue: grossText, onChanged: (v) => grossText = v,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cân tổng (kg)')),
        const SizedBox(height: 10),
        if (session.tareMode == TareMode.perBag) ...[
          TextFormField(initialValue: bagText, onChanged: (v) => bagText = v,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số bao (0 nếu là dữ liệu cũ)')),
          const SizedBox(height: 10),
          TextFormField(initialValue: tareText, onChanged: (v) => tareText = v,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Bì đã trừ của lượt (kg)',
                helperText: 'Sửa rõ bì của lượt này; không áp dụng lại mức bì mới.')),
          const SizedBox(height: 10),
        ] else ...[
          const Text('Lô dùng chế độ trừ bì cuối: lượt cân này không trừ bì riêng.'),
          const SizedBox(height: 10),
        ],
        TextFormField(initialValue: note, onChanged: (v) => note = v,
            decoration: const InputDecoration(labelText: 'Ghi chú')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu sửa')),
      ],
    ));
    if (ok != true) return;
    try {
      final gross = WeightMath.parseWeightGrams(grossText, decimals: session.decimals);
      final tare = session.tareMode == TareMode.perBag
          ? WeightMath.parseWeightGrams(tareText, decimals: session.decimals) : 0;
      if (session.tareMode == TareMode.perBag &&
          !RegExp(r'^\d{1,5}$').hasMatch(bagText)) {
        throw const FormatException('Số bao phải từ 0 đến 99.999.');
      }
      final bags = session.tareMode == TareMode.perBag
          ? int.parse(bagText) : 0;
      if (bags < 0 || bags > 99999) {
        throw const FormatException('Số bao phải từ 0 đến 99.999.');
      }
      WeightMath.netGrams(gross, tare);
      await _store.updateEntry(e.copyWith(grossGrams: gross, tareGrams: tare,
        bagCount: bags, note: note.trim()));
      await _refresh();
      _toast('Đã sửa và ghi nhật ký thay đổi.');
    } catch (err) { _error(err); }
  }

  Future<void> _deleteEntry(WeighEntry e) async {
    if (!await _confirm('Xóa lượt cân?', 'Số cân này sẽ bị xóa khỏi tổng. Nhật ký vẫn ghi nhận thao tác.', action: 'Xóa')) return;
    try { await _store.deleteEntry(e.id); await _refresh(); _toast('Đã xóa lượt cân.'); }
    catch (err) { _error(err); }
  }

  Future<void> _deleteSession(WeighSession session) async {
    if (!await _confirm('Xóa cả lô lúa?',
        'Xóa "${session.name}" và TẤT CẢ các lượt cân bên trong? Hãy sao lưu trước. Không thể hoàn tác.', action: 'Xóa cả lô')) {
      return;
    }
    try {
      await _store.deleteSession(session.id);
      if (_active?.id == session.id) _active = null;
      await _load();
    } catch (e) { _error(e); }
  }

  Future<void> _shareReceipt() async {
    final session = _active;
    if (session == null) return;
    try {
      await SharePlus.instance.share(ShareParams(
        sharePositionOrigin: shareSheetOrigin(context),
        text: ReceiptService.build(session, _entries),
        subject: 'Phiếu cân lúa - ${session.name}',
      ));
    } catch (e) { _error(e); }
  }

  Future<void> _shareCsv() async {
    final session = _active;
    if (session == null) return;
    try {
      final f = await _csv.createFile(session, _entries);
      await SharePlus.instance.share(ShareParams(
        sharePositionOrigin: shareSheetOrigin(context),
        files: [XFile(f.path)], text: 'Báo cáo cân lúa: ${session.name}',
      ));
    } catch (e) { _error(e); }
  }

  Future<void> _saveBackup() async {
    try {
      final f = await _backup.createBackup(_store);
      await SharePlus.instance.share(ShareParams(
        sharePositionOrigin: shareSheetOrigin(context),
        files: [XFile(f.path)],
        text: 'Bản sao lưu Cân Lúa Pro - chứa thông tin khách hàng; chỉ gửi nơi tin cậy.',
      ));
    } catch (e) { _error(e); }
  }

  Future<void> _importBackup() async {
    try {
      // file_picker 12: unified API returns a PlatformFile (not FilePickerResult).
      // Read via plugin bytes, supporting Android SAF and iOS Files/iCloud.
      final picked = await FilePicker.pickFile(
        type: FileType.custom, allowedExtensions: ['json']);
      if (picked == null) return;
      final bytesLength = await picked.length();
      if (bytesLength <= 0 || bytesLength > BackupService.maxImportBytes) {
        throw const FormatException('Tệp sao lưu phải nhỏ hơn 10 MB và không được trống.');
      }
      final decoded = _backup.readBackupBytes(await picked.readAsBytes());
      if (!mounted) return;
      if (!await _confirm('Khôi phục sổ cân?',
          'TẤT CẢ lô và lượt cân trên điện thoại này sẽ được THAY THẾ bằng dữ liệu trong tệp. '
          'Hãy sao lưu dữ liệu hiện có trước khi tiếp tục.', action: 'THAY THẾ dữ liệu')) {
        return;
      }
      await _store.restoreSnapshot(decoded);
      _active = null;
      await _load();
      _toast('Đã khôi phục dữ liệu thành công.');
    } catch (e) { _error(e); }
  }

  Future<void> _auditDialog() async {
    try {
      final logs = await _store.auditEvents(limit: 60);
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Nhật ký thao tác'),
        content: SizedBox(width: 460, height: 400, child: ListView.builder(
          itemCount: logs.length,
          itemBuilder: (ctx, i) => ListTile(
            dense: true, title: Text('${logs[i]['action']}'),
            subtitle: Text('${logs[i]['created_at']}'),
          ),
        )),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ));
    } catch (e) { _error(e); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _surface,
    appBar: AppBar(
      backgroundColor: _surface,
      title: const Row(children: [
        Icon(Icons.grass_rounded, color: _green, size: 29),
        SizedBox(width: 8),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('CÂN LÚA', style: TextStyle(fontWeight: FontWeight.w900, color: _dark)),
              Text(' PRO', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            Text(AppInfo.headerCaption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _green, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        )),
      ]),
      actions: [
        IconButton(tooltip: 'Mở cấu hình lô cân',
          onPressed: () => _switchTab(3),
          icon: const Icon(Icons.settings_outlined)),
        IconButton(tooltip: 'Chia sẻ phiếu cân',
          onPressed: _busy ? null : _shareReceipt, icon: const Icon(Icons.share_outlined)),
      ],
    ),
    body: _busy && _active == null
      ? const Center(child: CircularProgressIndicator())
      : _active == null
        ? Center(child: FilledButton(onPressed: () => _load(), child: const Text('Tải lại dữ liệu')))
        : IndexedStack(index: _tab, children: [_weighPage(), _reportPage(), _sessionsPage(), _utilitiesPage()]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab, height: 72,
      onDestinationSelected: _switchTab,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.scale_outlined),
            selectedIcon: Icon(Icons.scale), label: 'CÂN NHANH'),
        NavigationDestination(icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment), label: 'BÁO CÁO'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book), label: 'SỔ CÂN'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'CẤU HÌNH'),
      ],
    ),
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21),
      border: Border.all(color: const Color(0xFFDAE6DB))),
    child: child,
  );

  Widget _moneyItem(String caption, String money, {bool large = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(caption, style: TextStyle(fontSize: 13, color: large ? Colors.white70 : Colors.black54,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(money,
        style: TextStyle(fontSize: large ? 32 : 22, fontWeight: FontWeight.w900,
            color: large ? Colors.white : _dark))),
    ],
  );

  Widget _weighPage() {
    final s = _active!;
    final sum = WeighSummary.forSession(s, _entries);
    return RefreshIndicator(onRefresh: _refresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(15, 4, 15, 32), children: [
        Row(children: [
          Expanded(child: InkWell(onTap: () => _switchTab(2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ĐANG CÂN CHO LÔ', style: TextStyle(color: _green, fontWeight: FontWeight.w800, fontSize: 12)),
              Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: _dark)),
              if (s.customer.isNotEmpty) Text('Khách: ${s.customer}', maxLines: 1, overflow: TextOverflow.ellipsis),
            ]))),
          IconButton.filledTonal(tooltip: 'Sửa thông tin lô', onPressed: () => _sessionDialog(existing: s),
            icon: const Icon(Icons.edit_outlined)),
          const SizedBox(width: 7),
          IconButton.filled(tooltip: 'Tạo lô lúa mới', onPressed: () => _sessionDialog(), icon: const Icon(Icons.add)),
        ]),
        const SizedBox(height: 12),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NHẬP SỐ CÂN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _dark)),
          const SizedBox(height: 13),
          TextField(
            key: const ValueKey('gross_weight_input'),
            controller: _gross, focusNode: _grossFocus, autofocus: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _grossFocus.unfocus(),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _dark),
            decoration: InputDecoration(labelText: 'Số kg trên cân',
              hintText: s.decimals == 1 ? '125,5' : '125,55',
              suffixText: 'kg', prefixIcon: const Icon(Icons.scale, size: 25)),
          ),
          if (s.tareMode == TareMode.perBag) ...[
            const SizedBox(height: 9),
            TextField(controller: _bags,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Số bao lượt này (dùng tính bì)',
                prefixIcon: Icon(Icons.inventory_2_outlined))),
          ],
          if (_preview() != null) ...[
            const SizedBox(height: 8),
            Text(_preview()!,
              style: const TextStyle(color: _green, fontWeight: FontWeight.w800)),
          ],
          if (_showEntryNote || _note.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextField(controller: _note, textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: 'Ghi chú (không bắt buộc)',
                prefixIcon: const Icon(Icons.edit_note),
                suffixIcon: IconButton(tooltip: 'Ẩn ghi chú',
                  onPressed: () {
                    _note.clear();
                    setState(() => _showEntryNote = false);
                  },
                  icon: const Icon(Icons.close)))),
          ],
          if (!_showEntryNote && _note.text.isEmpty)
            Align(alignment: Alignment.centerRight, child: TextButton.icon(
              onPressed: () => setState(() => _showEntryNote = true),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Thêm ghi chú (tùy chọn)'),
            )),
          const SizedBox(height: 5),
          SizedBox(width: double.infinity, height: 64,
            child: FilledButton.icon(
              key: const ValueKey('save_weigh_entry_button'),
              onPressed: _busy ? null : _addManual,
              icon: const Icon(Icons.save_outlined, size: 27),
              label: const Text('LƯU LƯỢT CÂN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            )),
          const SizedBox(height: 6),
          const Text('Nhấn LƯU LƯỢT CÂN để thêm vào danh sách và cộng tổng. '
              'Phím Done trên bàn phím chỉ đóng bàn phím.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          if (_busy) const LinearProgressIndicator(),
        ])),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_green, Color(0xFF238858)]),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.tareMode == TareMode.afterTotal && s.finalTareGrams == 0 && sum.count > 0
              ? 'TẠM TÍNH • CHƯA NHẬP BÌ CUỐI' : 'TỔNG LÚA THỰC NHẬN',
              style: const TextStyle(color: Colors.white70,
                fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text('${WeightMath.weight(sum.net, s.decimals)} kg',
                style: const TextStyle(color: Colors.white, fontSize: 43, fontWeight: FontWeight.w900))),
            const SizedBox(height: 5),
            Text('${sum.count} lượt'
                '${s.tareMode == TareMode.perBag && sum.bags > 0 ? '  •  ${sum.bags} bao' : ''}'
                '  •  Tổng cân ${WeightMath.weight(sum.gross, s.decimals)} kg',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            Text('Quy đổi ${BagConversion.equivalent(sum.net, s.equivalentBagGrams)} bao '
                '(1 bao = ${WeightMath.weight(s.equivalentBagGrams, 2)} kg)',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            Text('Trừ bì ${WeightMath.weight(sum.tare, s.decimals)} kg  •  ${s.tareMode.label}',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Divider(height: 24, color: Colors.white38),
            _moneyItem('TỔNG THÀNH TIỀN', '${WeightMath.money(sum.amount)} đ', large: true),
          ]),
        ),
        const SizedBox(height: 10),
        InkWell(onTap: () => _switchTab(3),
          child: _card(Row(children: [
            const Icon(Icons.tune, color: _green),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '${WeightMath.money(s.priceVnd)} đ/kg  •  ${s.decimals} số lẻ  •  ${s.tareMode.label}',
              style: const TextStyle(color: _dark, fontWeight: FontWeight.w700))),
            const Icon(Icons.chevron_right, color: _green),
          ]))),
        const SizedBox(height: 17),
        Row(children: [
          const Expanded(child: Text('CÁC LƯỢT CÂN', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          TextButton.icon(onPressed: () => _switchTab(1),
              icon: const Icon(Icons.assessment_outlined), label: const Text('Báo cáo')),
        ]),
        if (_entries.isEmpty)
          Padding(padding: const EdgeInsets.all(28), child: Column(children: [
            Icon(Icons.scale_outlined, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text('Chưa có lượt cân nào.\nNhập kg rồi bấm LƯU LƯỢT CÂN.', textAlign: TextAlign.center),
          ])),
        for (var i = _entries.length - 1; i >= 0; i--) _entryCard(_entries[i], i + 1, s),
      ]),
    );
  }

  Widget _entryCard(WeighEntry e, int i, WeighSession s) => Card(
    margin: const EdgeInsets.only(bottom: 9), child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        CircleAvatar(backgroundColor: const Color(0xFFE1F1E6), child: Text('$i',
          style: const TextStyle(color: _green, fontWeight: FontWeight.bold))),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.tareMode == TareMode.perBag
              ? '${WeightMath.weight(e.netGrams, s.decimals)} kg thực'
              : '${WeightMath.weight(e.grossGrams, s.decimals)} kg cân tổng',
              style: const TextStyle(color: _dark, fontWeight: FontWeight.w900, fontSize: 21)),
          Text(s.tareMode == TareMode.perBag
              ? 'Cân ${WeightMath.weight(e.grossGrams, s.decimals)} − bì ${WeightMath.weight(e.tareGrams, s.decimals)} kg'
                  '${e.bagCount > 0 ? ' (${e.bagCount} bao)' : ''}'
              : 'Chưa trừ bì lượt này; bì được trừ ở cuối lô',
              style: const TextStyle(fontSize: 13)),
          Text('${BagConversion.equivalent(s.tareMode == TareMode.perBag ? e.netGrams : e.grossGrams, s.equivalentBagGrams)} bao quy đổi'
              '${s.tareMode == TareMode.afterTotal ? ' (chưa trừ bì cuối)' : ''}',
              style: const TextStyle(color: _green, fontWeight: FontWeight.bold)),
          Text(ReceiptService.date(e.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (e.note.isNotEmpty) Text(e.note, maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        PopupMenuButton<String>(tooltip: 'Sửa hoặc xóa lượt cân',
          onSelected: (v) => v == 'edit' ? _editEntry(e) : _deleteEntry(e),
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa số cân')),
            PopupMenuItem(value: 'delete', child: Text('Xóa số cân')),
          ],
        ),
      ]),
    ),
  );

  /// BẢNG BÁO CÁO: số kg từng lượt và bao quy đổi; tổng bì cuối chỉ trừ 1 lần.
  Widget _reportPage() {
    final s = _active!;
    final sum = WeighSummary.forSession(s, _entries);
    final deferredTare = s.tareMode == TareMode.afterTotal;
    final notice = deferredTare
        ? 'Các lượt hiển thị CÂN TỔNG và bao quy đổi TẠM TÍNH; bì chỉ trừ một lần ở TỔNG LÔ.'
        : 'Các lượt hiển thị số KG THỰC sau trừ bì theo số bao thực nhập.';
    return ListView(padding: const EdgeInsets.fromLTRB(15, 8, 15, 35), children: [
      Row(children: [
        const Expanded(child: Text('BÁO CÁO LƯỢT CÂN',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _dark))),
        const Icon(Icons.assessment_outlined, color: _green),
      ]),
      const SizedBox(height: 6),
      Text(s.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${sum.count} LƯỢT CÂN',
          style: const TextStyle(color: _green, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text('Tổng cân: ${WeightMath.weight(sum.gross, s.decimals)} kg',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        Text('Trừ bì: ${WeightMath.weight(sum.tare, s.decimals)} kg'),
        const SizedBox(height: 7),
        Text('TỔNG KG THỰC: ${WeightMath.weight(sum.net, s.decimals)} kg',
          style: const TextStyle(color: _green, fontSize: 23, fontWeight: FontWeight.w900)),
        Text('TƯƠNG ĐƯƠNG ${BagConversion.equivalent(sum.net, s.equivalentBagGrams)} BAO',
          style: const TextStyle(color: _green, fontSize: 19, fontWeight: FontWeight.w900)),
        Text(BagConversion.breakdown(sum.net, s.equivalentBagGrams, decimals: 2)),
        const SizedBox(height: 6),
        Text('Quy ước: 1 bao = ${WeightMath.weight(s.equivalentBagGrams, 2)} kg',
          style: const TextStyle(color: Colors.black54)),
        if (s.tareMode == TareMode.perBag)
          Text('Số bao thực nhập để trừ bì: ${sum.bags} bao',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        if (deferredTare && s.finalTareGrams == 0 && sum.count > 0)
          const Text('CHƯA NHẬP BÌ CUỐI — TỔNG KG THỰC CHỈ TẠM TÍNH',
            style: TextStyle(color: Color(0xFF9B5B06), fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text('Tổng tiền: ${WeightMath.money(sum.amount)} đ',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ])),
      const SizedBox(height: 12),
      Text(notice, style: const TextStyle(color: Color(0xFF816007), fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      const Text('CHI TIẾT TỪNG LƯỢT',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 9),
      if (_entries.isEmpty) const _NoReportRows(),
      for (var i = 0; i < _entries.length; i++)
        _reportEntryCard(_entries[i], i + 1, s),
      const SizedBox(height: 13),
      FilledButton.icon(onPressed: _shareCsv,
        icon: const Icon(Icons.file_download_outlined),
        label: const Text('XUẤT BÁO CÁO CSV / EXCEL')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: _shareReceipt,
        icon: const Icon(Icons.share_outlined), label: const Text('CHIA SẺ BẢNG CÂN')),
    ]);
  }

  Widget _reportEntryCard(WeighEntry e, int index, WeighSession s) {
    final isDeferred = s.tareMode == TareMode.afterTotal;
    final reportGrams = isDeferred ? e.grossGrams : e.netGrams;
    return Card(margin: const EdgeInsets.only(bottom: 9), child: Padding(
      padding: const EdgeInsets.all(13), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: const Color(0xFFE1F1E6),
              child: Text('$index', style: const TextStyle(color: _green, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${WeightMath.weight(reportGrams, s.decimals)} kg'
                '${isDeferred ? ' (chưa trừ bì)' : ' thực'}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
            Text('Cân tổng ${WeightMath.weight(e.grossGrams, s.decimals)} kg'
              '${isDeferred ? '' : ' − bì ${WeightMath.weight(e.tareGrams, s.decimals)} kg'}'),
          ])),
        ]),
        const SizedBox(height: 7),
        Text('QUY ĐỔI ${BagConversion.equivalent(reportGrams, s.equivalentBagGrams)} bao '
          '(${BagConversion.breakdown(reportGrams, s.equivalentBagGrams, decimals: 2)})',
          style: const TextStyle(color: _green, fontSize: 15, fontWeight: FontWeight.w800)),
        if (!isDeferred && e.bagCount > 0)
          Text('Số bao thực tế dùng trừ bì: ${e.bagCount}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(ReceiptService.date(e.createdAt), style: const TextStyle(color: Colors.black54)),
        if (e.note.isNotEmpty) Text(e.note),
      ])),
    );
  }

  Widget _sessionsPage() {
    final q = _search.text.trim().toLowerCase();
    final sessions = _sessions.where((s) =>
      s.name.toLowerCase().contains(q) || s.customer.toLowerCase().contains(q) ||
      s.variety.toLowerCase().contains(q)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(15, 7, 15, 28), children: [
      Row(children: [
        const Expanded(child: Text('SỔ CÂN CỦA TÔI',
            style: TextStyle(fontSize: 21, color: _dark, fontWeight: FontWeight.w900))),
        FilledButton.icon(onPressed: () => _sessionDialog(),
          icon: const Icon(Icons.add), label: const Text('LÔ MỚI')),
      ]),
      const SizedBox(height: 8),
      const Text('Mỗi khách hoặc chuyến lúa là một lô riêng. Dữ liệu được lưu trên điện thoại.'),
      const SizedBox(height: 13),
      TextField(controller: _search, decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search), labelText: 'Tìm tên lô, khách hoặc giống lúa',
        suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: _search.clear,
          icon: const Icon(Icons.close)),
      )),
      const SizedBox(height: 14),
      if (sessions.isEmpty) const Padding(padding: EdgeInsets.all(22),
        child: Center(child: Text('Không tìm thấy lô phù hợp.'))),
      for (final session in sessions) Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(15, 8, 6, 8),
          leading: Icon(session.id == _active?.id ? Icons.check_circle : Icons.folder_open,
            size: 30, color: _green),
          title: Text(session.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Text('${session.customer.isEmpty ? 'Chưa đặt tên khách' : session.customer}'
              '${session.variety.isEmpty ? '' : ' • ${session.variety}'}\n'
              '${WeightMath.money(session.priceVnd)} đ/kg • ${ReceiptService.date(session.createdAt)}'),
          isThreeLine: true,
          onTap: () async {
            await _load(selectId: session.id);
            if (mounted) setState(() => _tab = 0);
          },
          trailing: PopupMenuButton<String>(
            onSelected: (v) => v == 'edit'
              ? _sessionDialog(existing: session) : _deleteSession(session),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'edit', child: Text('Sửa thông tin')),
              PopupMenuItem(value: 'delete', child: Text('Xóa lô')),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _utilitiesPage() {
    final s = _active!;
    final sum = WeighSummary.forSession(s, _entries);
    final tareDescription = s.tareMode == TareMode.perBag
        ? '${WeightMath.weight(s.tarePerBagGrams, s.decimals)} kg/bao'
        : 'Bì cuối ${WeightMath.weight(s.finalTareGrams, s.decimals)} kg';
    return ListView(padding: const EdgeInsets.fromLTRB(15, 6, 15, 38), children: [
    const Text('CẤU HÌNH LÔ CÂN',
        style: TextStyle(fontSize: 21, color: _dark, fontWeight: FontWeight.w900)),
    const SizedBox(height: 4),
    Text('Áp dụng cho: ${s.name}',
        style: const TextStyle(color: _green, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('Chỉnh đơn giá, cách trừ bì, số lẻ và kg/bao tại đây. '
        'Khi cân chỉ cần nhập số kg, số bao (nếu có) rồi bấm LƯU LƯỢT CÂN.'),
    const SizedBox(height: 12),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('1. ĐƠN GIÁ VÀ THANH TOÁN',
        style: TextStyle(fontSize: 17, color: _dark, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: _price,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Đơn giá (đồng/kg)',
            prefixIcon: Icon(Icons.payments_outlined), hintText: '6500'))),
        const SizedBox(width: 8),
        FilledButton.tonal(onPressed: _busy ? null : _savePrice,
          child: const Text('LƯU GIÁ')),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Text('Đã trả: ${WeightMath.money(s.paidVnd)} đ')),
        TextButton(onPressed: _paidDialog, child: const Text('SỬA ĐÃ TRẢ')),
      ]),
      Text(sum.remaining(s.paidVnd) >= 0
        ? 'Còn phải trả: ${WeightMath.money(sum.remaining(s.paidVnd))} đ'
        : 'Đã trả dư: ${WeightMath.money(-sum.remaining(s.paidVnd))} đ',
        style: const TextStyle(color: _green, fontWeight: FontWeight.w800)),
    ])),
    const SizedBox(height: 12),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('2. SỐ LẺ CỦA CÂN',
        style: TextStyle(fontSize: 17, color: _dark, fontWeight: FontWeight.w900)),
      const SizedBox(height: 9),
      SegmentedButton<int>(segments: const [
        ButtonSegment(value: 1, label: Text('1 số lẻ')),
        ButtonSegment(value: 2, label: Text('2 số lẻ')),
      ], selected: {s.decimals}, onSelectionChanged: (v) => _changeDecimals(v.first)),
      const SizedBox(height: 7),
      const Text('Ví dụ: 125,5 kg hoặc 125,55 kg. Nếu đã lưu số cân có 2 số lẻ, '
        'phần mềm sẽ không cho giảm xuống 1 số lẻ.'),
    ])),
    const SizedBox(height: 12),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('3. PHƯƠNG PHÁP TRỪ BÌ',
        style: TextStyle(fontSize: 17, color: _dark, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text('${s.tareMode.label} • $tareDescription',
        style: const TextStyle(color: _green, fontWeight: FontWeight.w800)),
      const SizedBox(height: 9),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _tareSettings, icon: const Icon(Icons.tune),
        label: const Text('CÀI ĐẶT CÁCH TRỪ BÌ'))),
      if (s.tareMode == TareMode.afterTotal) ...[
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: TextField(controller: _finalTare,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Tổng bì trừ cuối (kg)',
              helperText: 'Nhập một lần sau khi cân'))),
          const SizedBox(width: 8),
          FilledButton.tonal(onPressed: _saveFinalTare,
            child: const Text('LƯU BÌ')),
        ]),
      ],
      const SizedBox(height: 7),
      const Text('Không thể đổi phương pháp khi lô đã có lượt cân. '
          'Điều chỉnh bì theo thiết lập đang dùng không xóa lịch sử.'),
    ])),
    const SizedBox(height: 12),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('4. QUY ĐỔI BAO',
        style: TextStyle(fontSize: 17, color: _dark, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      Text('1 bao quy đổi = ${WeightMath.weight(s.equivalentBagGrams, 2)} kg',
        style: const TextStyle(color: _green, fontWeight: FontWeight.w800)),
      const SizedBox(height: 9),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _bagConversionSettings,
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('THAY ĐỔI KG / BAO QUY ĐỔI'))),
      const SizedBox(height: 6),
      const Text('Bao quy đổi chỉ dùng để thống kê; số bao thực tế trong từng lượt '
        'được nhập ở màn hình CÂN NHANH khi trừ bì theo đầu bao.'),
    ])),
    const SizedBox(height: 20),
    const Text('TIỆN ÍCH VÀ SAO LƯU',
        style: TextStyle(fontSize: 20, color: _dark, fontWeight: FontWeight.w900)),
    const SizedBox(height: 12),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('CHIA SẺ VÀ BÁO CÁO',
          style: TextStyle(fontSize: 17, color: _dark, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _shareReceipt,
        icon: const Icon(Icons.send_outlined), label: const Text('Gửi phiếu cân qua Zalo / tin nhắn'))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _shareCsv,
        icon: const Icon(Icons.file_download_outlined), label: const Text('Xuất Excel (CSV) của lô này'))),
    ])),
    const SizedBox(height: 13),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('SAO LƯU - ĐỔI ĐIỆN THOẠI',
          style: TextStyle(fontSize: 17, color: _dark, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      const Text('Sao lưu tất cả lô và lượt cân sang tệp JSON. Chỉ gửi tệp cho người tin cậy vì có thông tin khách hàng.'),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.tonalIcon(onPressed: _saveBackup,
        icon: const Icon(Icons.cloud_upload_outlined), label: const Text('Sao lưu tất cả dữ liệu'))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _importBackup,
        icon: const Icon(Icons.restore_outlined), label: const Text('Khôi phục từ tệp đã sao lưu'))),
      const SizedBox(height: 8),
      const Text('Cảnh báo: khôi phục sẽ thay thế toàn bộ dữ liệu hiện tại.',
          style: TextStyle(color: Color(0xFF925A00))),
    ])),
    const SizedBox(height: 13),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('AN TOÀN VÀ DỄ SỬ DỤNG',
        style: TextStyle(fontSize: 17, color: _dark, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      const Text('• Cấu hình bì theo đầu bao hoặc trừ cuối cho từng lô.\n'
          '• Chọn số bao nếu trừ đầu bao, nhập kg và bấm LƯU LƯỢT CÂN.\n'
          '• Báo cáo từng lượt và đổi bao theo kg/bao tùy chỉnh.\n'
          '• Phiếu cân, tổng tiền và tiền đã trả được cập nhật ngay.\n'
          '• Không cần mạng để nhập cân và xem sổ.\n'
          '• Trước khi đổi máy hoặc xóa ứng dụng hãy sao lưu dữ liệu.\n'
          '• Cân lúa là giao dịch thực tế: luôn kiểm tra cân và đơn giá.'),
      const SizedBox(height: 8),
      TextButton.icon(onPressed: _auditDialog, icon: const Icon(Icons.history),
          label: const Text('Xem nhật ký thay đổi')),
    ])),
    const SizedBox(height: 13),
    _card(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('GIỚI THIỆU PHẦN MỀM',
        style: TextStyle(fontSize: 17, color: _dark, fontWeight: FontWeight.w900)),
      SizedBox(height: 10),
      Row(children: [
        Icon(Icons.info_outline, color: _green), SizedBox(width: 10),
        Expanded(child: Text(AppInfo.titleWithVersion,
          style: TextStyle(fontWeight: FontWeight.w800))),
      ]),
      SizedBox(height: 8),
      Row(children: [
        Icon(Icons.edit_note_outlined, color: _green), SizedBox(width: 10),
        Expanded(child: Text(AppInfo.editorLabel,
          style: TextStyle(fontWeight: FontWeight.w700))),
      ]),
      SizedBox(height: 8),
      Text('Android và iOS • Nhập cân thủ công • Không AI',
        style: TextStyle(color: Colors.black54)),
    ])),
    const SizedBox(height: 18),
    const Center(child: Column(children: [
      Icon(Icons.grass, color: _green), SizedBox(height: 3),
      Text(AppInfo.titleWithVersion, style: TextStyle(fontWeight: FontWeight.bold)),
      Text(AppInfo.editorLabel),
      Text('Bản phát triển thử nghiệm; chưa thay thế chứng từ kế toán.'),
    ])),
  ]);
}
}

class _NoReportRows extends StatelessWidget {
  const _NoReportRows();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Chưa có số cân nào. Vào CÂN NHANH, nhập kg và bấm LƯU LƯỢT CÂN.'),
  );
}
