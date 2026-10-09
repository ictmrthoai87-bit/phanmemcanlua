#!/usr/bin/env bash
# Generate a legitimate signed IPA on macOS; never fake an IPA by renaming a ZIP.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p output
LOG="$ROOT/output/ipa_build_$(date '+%Y%m%d_%H%M%S').log"
exec > >(tee -a "$LOG") 2>&1
error_notice() { status=$?; echo "KHONG TAO DUOC IPA (exit=$status). Nhat ky: $LOG" >&2; exit "$status"; }
trap error_notice ERR
printf '\n=== CAN LUA PRO V0.6.3 | Edit: Le Ngoc Thoai ===\n'
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo 'Can macOS + Xcode de build va ky IPA cho iPhone.' >&2; exit 1
fi
for prog in flutter xcodebuild xcrun python3 unzip ditto codesign; do
  if ! command -v "$prog" >/dev/null 2>&1; then
    echo "Chua co $prog. Cai Flutter/Xcode va xcode-select truoc." >&2; exit 1
  fi
done
xcodebuild -version
flutter --version
# Keep user's existing iOS Xcode project and signing configuration.
if [[ ! -f ios/Runner.xcodeproj/project.pbxproj ]]; then
  echo 'Tao Xcode project iOS tu ma Flutter (chi lan dau)...'
  flutter create --platforms=ios --org vn.canlua --project-name lua_can_pro .
fi

DEFAULT_BUNDLE_ID='vn.canlua.canluapro'
if [[ -t 0 ]]; then
  current_bundle="${IOS_BUNDLE_ID:-$DEFAULT_BUNDLE_ID}"
  echo "Bundle ID mac dinh: $current_bundle"
  read -r -p 'Nhap Bundle ID da dang ky voi Apple (Enter giu nguyen): ' user_bundle
  IOS_BUNDLE_ID="${user_bundle:-$current_bundle}"
else
  IOS_BUNDLE_ID="${IOS_BUNDLE_ID:-$DEFAULT_BUNDLE_ID}"
fi
export IOS_BUNDLE_ID
printf 'IOS_BUNDLE_ID=%s\n' "$IOS_BUNDLE_ID"
python3 scripts/configure_ios_native.py
flutter pub get
if [[ -f ios/Podfile ]]; then
  command -v pod >/dev/null 2>&1 || { echo 'Thieu CocoaPods (pod). Cai CocoaPods truoc.' >&2; exit 1; }
  (cd ios && pod install)
fi
flutter analyze --fatal-infos
flutter test

printf '\nChon kieu IPA:\n'
echo '  1) TestFlight / App Store (Apple Distribution)'
echo '  2) Cai thu tren iPhone duoc cap phep (development)'
echo '  3) Cai tren danh sach iPhone da dang ky (ad-hoc)'
echo '  4) Mo Xcode de cai dat Signing, chua tao IPA'
if [[ -t 0 ]]; then
  read -r -p 'Lua chon [1]: ' opt
else
  opt="${IOS_IPA_MODE:-1}"
fi
case "${opt:-1}" in
  1|app-store) export_method=app-store;;
  2|development) export_method=development;;
  3|ad-hoc) export_method=ad-hoc;;
  4|xcode)
    open ios/Runner.xcworkspace
    echo 'Chon Team + Bundle Identifier va bat Automatically manage signing trong Xcode.'
    echo 'Sau do chay lai TAO_IPA_TREN_MAC.command.'
    exit 0;;
  *) echo 'Lua chon khong hop le.' >&2; exit 2;;
esac

echo 'Kiem tra code signing identities (chung chi duoc cai trong Keychain):'
security find-identity -v -p codesigning || true
echo 'Neu thieu certificate/provisioning phu hop, build IPA se that bai: cau hinh trong Xcode.'
echo "Dang tao IPA ky so, che do: $export_method"
if [[ -n "${IOS_EXPORT_OPTIONS_PLIST:-}" ]]; then
  [[ -f "$IOS_EXPORT_OPTIONS_PLIST" ]] || { echo 'ExportOptions.plist khong ton tai.' >&2; exit 1; }
  flutter build ipa --release --export-options-plist="$IOS_EXPORT_OPTIONS_PLIST"
else
  flutter build ipa --release --export-method "$export_method"
fi

shopt -s nullglob
files=(build/ios/ipa/*.ipa)
[[ ${#files[@]} -gt 0 ]] || { echo 'Build khong sinh IPA. Xem log va Signing trong Xcode.' >&2; exit 1; }
chosen="${files[0]}"
for candidate in "${files[@]}"; do
  if [[ "$candidate" -nt "$chosen" ]]; then chosen="$candidate"; fi
done
DEST="$ROOT/output/CAN_LUA_PRO_V0.6.3_${export_method}_iOS.ipa"
cp -f "$chosen" "$DEST"
unzip -tqq "$DEST" || { echo 'IPA bi loi cau truc ZIP.' >&2; exit 1; }
TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT
ditto -x -k "$DEST" "$TMP_DIR"
apps=("$TMP_DIR"/Payload/*.app)
[[ ${#apps[@]} -eq 1 && -d "${apps[0]}" ]] || { echo 'IPA khong co Payload/*.app.' >&2; exit 1; }
codesign --verify --deep --strict "${apps[0]}" || { echo 'Chu ky ung dung khong hop le.' >&2; exit 1; }
[[ -e "${apps[0]}/embedded.mobileprovision" ]] || { echo 'IPA thieu provisioning profile.' >&2; exit 1; }
echo '=================================='
echo 'DA TAO IPA CO CHU KY:'
echo "$DEST"
ls -lh "$DEST"
echo '=================================='
echo 'Luu y: app-store IPA cai qua TestFlight/App Store, KHONG chuyen vao iPhone de bam cai truc tiep.'
echo 'development/ad-hoc chi cai cho thiet bi duoc provisioning profile cho phep.'
echo "Log: $LOG"
