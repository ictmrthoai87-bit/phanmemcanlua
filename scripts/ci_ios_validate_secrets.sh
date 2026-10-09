#!/usr/bin/env bash
set -Eeuo pipefail
missing=()
for name in IOS_BUNDLE_ID APPLE_TEAM_ID BUILD_CERTIFICATE_BASE64 P12_PASSWORD BUILD_PROVISION_PROFILE_BASE64; do
  if [[ -z "${!name:-}" ]]; then missing+=("$name"); fi
done
if ((${#missing[@]})); then
  echo "THIEU GitHub Secrets: ${missing[*]}" >&2
  echo 'Xem docs/TAO_IPA_GITHUB_WINDOWS.md' >&2
  exit 2
fi
if [[ ! "$IOS_BUNDLE_ID" =~ ^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z][A-Za-z0-9-]*){2,}$ ]]; then
  echo 'IOS_BUNDLE_ID khong hop le. Vi du: vn.canlua.canluapro' >&2; exit 2
fi
if [[ ! "$APPLE_TEAM_ID" =~ ^[A-Za-z0-9]{10}$ ]]; then
  echo 'APPLE_TEAM_ID phai la Apple Team ID gom 10 ky tu.' >&2; exit 2
fi
echo 'DA DU 5 GitHub Secrets can de ky IPA.'
