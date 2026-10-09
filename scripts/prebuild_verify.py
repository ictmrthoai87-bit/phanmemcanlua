"""Pre-build checks, no Flutter required. Not a replacement for flutter analyze/build."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / 'lib/screens/farmer_home_screen.dart'
source = UI.read_text(encoding='utf-8-sig')
checks = {
    'No unused dart:io in home screen': "import 'dart:io';" not in source,
    'FilePicker 12 import restored': "import 'package:file_picker/file_picker.dart';" in source,
    'file picker 12 API': 'FilePicker.pickFile(' in source,
    'no legacy FilePicker.platform': 'FilePicker.platform' not in source,
    'no deprecated OCR or camera': all(x not in source for x in ('OcrService', 'google_mlkit_text_recognition','mobile_scanner')),
    'app root correct': 'LuaCanProApp' in (ROOT / 'lib/main.dart').read_text(encoding='utf-8'),
    'test app name correct': 'MyApp(' not in (ROOT / 'test/widget_test.dart').read_text(encoding='utf-8'),
    'locked file_picker version': 'file_picker: 12.0.0' in (ROOT/'pubspec.yaml').read_text(encoding='utf-8'),
}
for name, ok in checks.items():
    print(('PASS' if ok else 'FAIL') + ': ' + name)
if not all(checks.values()):
    sys.exit(1)
print('PASS: source preflight; still run flutter analyze, test, and real APK compile.')
