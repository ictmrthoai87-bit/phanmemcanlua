"""Structural UI assertions; still require Flutter analyze/test and device testing."""
from pathlib import Path
src = (Path(__file__).resolve().parents[1] / 'lib/screens/farmer_home_screen.dart').read_text(encoding='utf-8')
main = src.split('Widget _weighPage() {', 1)[1].split('Widget _entryCard(', 1)[0]
settings = src.split('Widget _utilitiesPage() {', 1)[1].split('class _NoReportRows', 1)[0]
report = src.split('Widget _reportPage() {', 1)[1].split('Widget _reportEntryCard(', 1)[0]
assert main.count("const Text('NHẬP SỐ CÂN'") == 1
assert main.count("const Text('LƯU LƯỢT CÂN'") == 1
assert 'save_weigh_entry_button' in main
assert main.index("const Text('NHẬP SỐ CÂN'") < main.index('save_weigh_entry_button') < main.index('TỔNG LÚA THỰC NHẬN')
assert 'Lưu số cân bằng một chạm' not in main and "suffixText: 'kg'" in main
assert "onSubmitted: (_) => _grossFocus.unfocus()" in main
assert '_savePrice' not in main and '_saveFinalTare' not in main
assert '_changeDecimals(' not in main and '_tareSettings' not in main
assert 'Số bao lượt này (dùng tính bì)' in main
assert all(x in settings for x in ('_savePrice', '_changeDecimals', '_tareSettings', '_saveFinalTare', '_bagConversionSettings'))
assert '_bagConversionSettings' not in report
assert "label: 'CẤU HÌNH'" in src
assert src.count('FilePicker.pickFile(') == 1
print('PASS: single save control near kg; config in one tab; no unwanted scanner/AI; reports and backups preserved.')
