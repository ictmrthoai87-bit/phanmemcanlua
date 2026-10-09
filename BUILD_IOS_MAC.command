#!/bin/bash
# Double click on Mac, or run: bash BUILD_IOS_MAC.command
set -e
cd "$(dirname "$0")"
echo '=== CAN LUA PRO - BUILD IPHONE / IPAD ==='
echo '1 - Chuan bi project iOS'
echo '2 - Kiem tra ma nguon va bai test'
echo '3 - Build iOS Simulator'
echo '4 - Mo Xcode, cai thu len iPhone / iPad'
echo '5 - Tao IPA da ky de phat hanh'
read -r -p 'Chon 1-5 [mac dinh 4]: ' choice || true
case "${choice:-4}" in
  1) arg=--prepare;;
  2) arg=--check;;
  3) arg=--simulator;;
  4) arg=--install;;
  5) arg=--ipa;;
  *) echo 'Lua chon khong hop le'; exit 2;;
esac
bash scripts/build_ios_macos.sh "$arg"
echo ''
read -r -p 'Nhan Enter de ket thuc...' _ || true
