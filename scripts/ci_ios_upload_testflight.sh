#!/usr/bin/env bash
set -Eeuo pipefail
for key in APPLE_API_KEY_ID APPLE_API_ISSUER_ID APPLE_API_PRIVATE_KEY_BASE64; do
  if [[ -z "${!key:-}" ]]; then echo "Thieu GitHub Secret: $key" >&2; exit 2; fi
done
shopt -s nullglob
ipas=(build/ios/ipa/*.ipa)
((${#ipas[@]} == 1)) || { echo 'Khong tim thay IPA de upload TestFlight' >&2; exit 1; }
mkdir -p "$HOME/.appstoreconnect/private_keys"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${APPLE_API_KEY_ID}.p8"
export KEY_PATH
python3 - <<'PY'
import base64,os,pathlib
p=pathlib.Path(os.environ['KEY_PATH'])
p.write_bytes(base64.b64decode(os.environ['APPLE_API_PRIVATE_KEY_BASE64'].strip(),validate=True))
p.chmod(0o600)
PY
# xcrun altool supports API-key authentication in Apple's official Flutter release instructions.
xcrun altool --upload-app --type ios -f "${ipas[0]}" --apiKey "$APPLE_API_KEY_ID" --apiIssuer "$APPLE_API_ISSUER_ID"
echo 'Upload hoan tat; doi Apple xu ly truoc khi hien tren TestFlight.'
