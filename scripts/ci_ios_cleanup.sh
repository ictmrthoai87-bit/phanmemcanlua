#!/usr/bin/env bash
set +e
if [[ -f "$RUNNER_TEMP/canlua_signing_metadata.txt" ]]; then
 uuid="$(python3 -c 'import json,os;print(json.load(open(os.environ["RUNNER_TEMP"]+"/canlua_signing_metadata.txt"))["uuid"])' 2>/dev/null)"
 if [[ -n "$uuid" ]]; then rm -f "$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"; fi
fi
security delete-keychain "$RUNNER_TEMP/canlua-signing.keychain-db" >/dev/null 2>&1
rm -rf "$RUNNER_TEMP/canlua-signing" "$RUNNER_TEMP/canlua_ExportOptions.plist" "$RUNNER_TEMP/canlua_signing_metadata.txt"
if [[ -d "$HOME/.appstoreconnect/private_keys" ]]; then
 find "$HOME/.appstoreconnect/private_keys" -maxdepth 1 -name 'AuthKey_*.p8' -delete
fi
