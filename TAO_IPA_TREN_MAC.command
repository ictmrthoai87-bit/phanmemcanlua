#!/bin/bash
# CAN LUA PRO 0.6.3 — double click or: bash TAO_IPA_TREN_MAC.command
set -Eeuo pipefail
cd "$(dirname "$0")"
echo "========================================================="
echo "  CAN LUA PRO V0.6.3 - TAO IPA (iPhone/iPad)"
echo "  Edit: Le Ngoc Thoai"
echo "========================================================="
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "LOI: Can may Mac co Xcode. Windows/Linux khong the build iOS native."
  exit 1
fi
bash scripts/create_signed_ipa_macos.sh "$@"
echo
read -r -p "Nhan Enter de dong cua so..." _ || true
