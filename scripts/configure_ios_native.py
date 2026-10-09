#!/usr/bin/env python3
"""Idempotent iOS native settings applied after 'flutter create --platforms=ios'.

No signing keys or credentials are stored. Set IOS_BUNDLE_ID if available.
"""
from pathlib import Path
import os
import plistlib
import re
import shutil
import sys

root = Path(__file__).resolve().parent.parent
ios = root / 'ios'
pbx = ios / 'Runner.xcodeproj/project.pbxproj'
plist = ios / 'Runner/Info.plist'
podfile = ios / 'Podfile'
bundle = os.environ.get('IOS_BUNDLE_ID', '').strip()

if not pbx.exists() or not plist.exists():
    sys.exit('LOI: Chua co project iOS. Tren Mac hay chay flutter create --platforms=ios --org vn.canlua .')
if bundle and not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z][A-Za-z0-9-]*){2,}', bundle):
    sys.exit('LOI: IOS_BUNDLE_ID khong hop le. Vi du: vn.tencongty.canluapro')

raw = pbx.read_text(encoding='utf-8')
raw = re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.5;', raw)
if bundle:
    raw, count = re.subn(r'(PRODUCT_BUNDLE_IDENTIFIER = )[^;]+;', lambda m: m.group(1)+bundle+';', raw)
    if not count:
        sys.exit('LOI: khong tim thay PRODUCT_BUNDLE_IDENTIFIER trong Xcode project')
pbx.write_text(raw, encoding='utf-8')

with plist.open('rb') as f:
    info = plistlib.load(f)
info['CFBundleDisplayName'] = 'Cân Lúa Pro'
info['CFBundleDevelopmentRegion'] = 'vi'
info['CFBundleLocalizations'] = ['vi', 'en']
info['CFBundleAllowMixedLocalizations'] = True
for key in ('NSCameraUsageDescription', 'NSPhotoLibraryUsageDescription',
            'NSMicrophoneUsageDescription', 'NSPhotoLibraryAddUsageDescription'):
    info.pop(key, None)
with plist.open('wb') as f:
    plistlib.dump(info, f, sort_keys=False)

if podfile.exists():
    pods = podfile.read_text(encoding='utf-8')
    if re.search(r'^\s*platform\s*:ios\s*,', pods, flags=re.M):
        pods = re.sub(r'^\s*platform\s*:ios\s*,[^\n]+', "platform :ios, '15.5'", pods, count=1, flags=re.M)
    else:
        pods = "platform :ios, '15.5'\n" + pods
    podfile.write_text(pods, encoding='utf-8')

source = root / 'ios_assets/AppIcon.appiconset'
target = ios / 'Runner/Assets.xcassets/AppIcon.appiconset'
if not target.parent.exists():
    sys.exit('LOI: khong tim thay Runner/Assets.xcassets - Flutter iOS chua tao day du')
target.mkdir(parents=True, exist_ok=True)
for asset in source.iterdir():
    if asset.is_file():
        shutil.copy2(asset, target / asset.name)

print('OK: iOS display name, Vietnamese localization, target iOS 15.5, app icons.')
if bundle:
    print('OK: iOS Bundle Identifier =', bundle)
else:
    print('Luu y: Bundle ID mac dinh can duoc kiem tra/chinh trong Xcode khi ky so.')
print('Khong yeu cau camera. Apple Signing va Privacy Manifest can ra soat truoc phat hanh.')
