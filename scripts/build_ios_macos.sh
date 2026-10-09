#!/usr/bin/env bash
# Can Lua Pro - iOS build commands. macOS + Xcode + Flutter + CocoaPods.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p output
LOG="$ROOT/output/ios_$(date '+%Y%m%d_%H%M%S').log"
exec > >(tee -a "$LOG") 2>&1
action="${1:---prepare}"
print_help() {
  echo 'Su dung: bash scripts/build_ios_macos.sh --prepare|--check|--simulator|--install|--ipa'
  echo '  --prepare   Tao va cau hinh project Xcode (khong can Apple Developer)'
  echo '  --check     Flutter analyze + test'
  echo '  --simulator Build .app cho Simulator (KHONG cai truc tiep tren iPhone)'
  echo '  --install   Mo Xcode de ky/chay app tren iPhone'
  echo '  --ipa       Xuat IPA release da ky (can Apple Developer Team va provisioning)'
  echo 'Cau hinh: export IOS_BUNDLE_ID=vn.tencongty.canluapro'
}
case "$action" in --prepare|--check|--simulator|--install|--ipa) ;; *) print_help; exit 2;; esac
if [[ "$(uname -s)" != 'Darwin' ]]; then echo 'Can macOS va Xcode de build iPhone.' >&2; exit 1; fi
for item in flutter xcodebuild xcrun python3 pod; do
  if ! command -v "$item" >/dev/null 2>&1; then
    echo "Chua tim thay $item. Cai Xcode, Flutter va CocoaPods truoc khi build." >&2; exit 1
  fi
done
echo '===== CAN LUA PRO iOS ====='
echo "Mode: $action | Log: $LOG"
flutter --version
xcodebuild -version
if [[ ! -f ios/Runner.xcodeproj/project.pbxproj ]]; then
  echo 'Tao iOS project moi (khong sua project da ky neu ton tai)...'
  flutter create --platforms=ios --org vn.canlua --project-name lua_can_pro .
else
  echo 'Da co iOS Runner: giu nguyen cac cau hinh Apple Signing.'
fi
flutter pub get
python3 scripts/configure_ios_native.py
if [[ -f ios/Podfile ]]; then (cd ios && pod install); fi
# Analyze before build. Do not silently skip source warnings.
if [[ "$action" != '--prepare' ]]; then
  flutter analyze --fatal-infos
  flutter test
fi
case "$action" in
  --prepare)
    echo 'Da san sang. Chay bash scripts/build_ios_macos.sh --install de mo Xcode.';;
  --check)
    echo 'Da hoan thanh analyze/test (chua build iPhone).';;
  --simulator)
    flutter build ios --simulator
    test -d build/ios/iphonesimulator/Runner.app
    ditto -c -k --sequesterRsrc --keepParent build/ios/iphonesimulator/Runner.app output/CAN_LUA_PRO_iOS_SIMULATOR_ONLY.zip
    echo 'Simulator ZIP: output/CAN_LUA_PRO_iOS_SIMULATOR_ONLY.zip (khong phai IPA)';;
  --install)
    echo 'Xcode > Runner > Signing & Capabilities > Team > Automatically manage signing.'
    echo 'Chon iPhone / iPad da ket noi, nhan Run. Bat Developer Mode tren iPhone neu can.'
    open ios/Runner.xcworkspace;;
  --ipa)
    echo 'Can Apple Developer membership, Team va profile ky so hop le.'
    echo 'Neu chua cau hinh, hay chay --install truoc.'
    flutter build ipa --release
    shopt -s nullglob
    ipa_files=(build/ios/ipa/*.ipa)
    if [[ ${#ipa_files[@]} -eq 0 ]]; then echo 'Khong tim thay IPA da ky.' >&2; exit 1; fi
    for f in "${ipa_files[@]}"; do cp "$f" output/; done
    echo 'Da luu IPA: output/ (chi cai tren thiet bi qua cach phan phoi Apple cho phep).';;
esac
echo 'XONG - log: '"$LOG"
