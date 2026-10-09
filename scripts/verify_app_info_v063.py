#!/usr/bin/env python3
"""Basic version/credit consistency check without Flutter SDK."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
info = (root/'lib/core/app_info.dart').read_text(encoding='utf-8')
pub = (root/'pubspec.yaml').read_text(encoding='utf-8')
ui = (root/'lib/screens/farmer_home_screen.dart').read_text(encoding='utf-8')
version, build = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)',pub,re.M).groups()
assert "version = '"+version+"'" in info
assert "buildNumber = "+build+";" in info
assert "'Edit: Lê Ngọc Thoại'" in info
assert 'AppInfo.headerCaption' in ui
assert ui.count('AppInfo.titleWithVersion') >= 2
assert ui.count('AppInfo.editorLabel') >= 2
assert 'schema' not in str(root/'lib/core/app_info.dart')
print('PASS: version',version,'build',build,'and editor visible in appbar/settings/footer')
