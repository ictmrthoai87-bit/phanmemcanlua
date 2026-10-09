#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
bash scripts/build_ios_macos.sh --check
