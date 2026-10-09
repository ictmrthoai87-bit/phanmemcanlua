#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob
ipas=(build/ios/ipa/*.ipa)
if ((${#ipas[@]} != 1)); then echo 'Khong co dung 1 IPA sau build' >&2; exit 1; fi
ipa="${ipas[0]}"
unzip -tqq "$ipa"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
ditto -x -k "$ipa" "$tmp"
apps=("$tmp"/Payload/*.app)
if ((${#apps[@]} != 1)); then echo 'IPA khong chua Payload/Runner.app' >&2; exit 1; fi
codesign --verify --deep --strict "${apps[0]}"
test -s "${apps[0]}/embedded.mobileprovision" || { echo 'IPA thieu provisioning profile' >&2; exit 1; }
actual_bundle="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "${apps[0]}/Info.plist")"
if [[ "$actual_bundle" != "$IOS_BUNDLE_ID" ]]; then
  echo 'IPA Bundle ID sai so voi IOS_BUNDLE_ID' >&2; exit 1
fi
printf 'IPA DA KY VA KIEM TRA OK: %s\n' "$ipa"
