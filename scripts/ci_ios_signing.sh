#!/usr/bin/env bash
# Do not print, commit, or archive secrets. Runs on a fresh GitHub-hosted macOS VM.
set -Eeuo pipefail
bash scripts/ci_ios_validate_secrets.sh
SECRET_DIR="$RUNNER_TEMP/canlua-signing"
mkdir -p "$SECRET_DIR" "$HOME/Library/MobileDevice/Provisioning Profiles"
chmod 700 "$SECRET_DIR"
export CERT_PATH="$SECRET_DIR/distribution.p12"
export PROVISIONING_PATH="$SECRET_DIR/distribution.mobileprovision"
python3 - <<'PY'
import os, base64, pathlib
for source, target in [('BUILD_CERTIFICATE_BASE64','CERT_PATH'), ('BUILD_PROVISION_PROFILE_BASE64','PROVISIONING_PATH')]:
    data = base64.b64decode(os.environ[source].strip(), validate=True)
    if len(data) < 100:
        raise SystemExit(f'Secret {source} qua ngan, kiem tra cach ma hoa base64')
    path = pathlib.Path(os.environ[target])
    path.write_bytes(data)
    path.chmod(0o600)
PY
KEYCHAIN_PATH="$RUNNER_TEMP/canlua-signing.keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -hex 24)"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH"
security default-keychain -d user -s "$KEYCHAIN_PATH"
security import "$CERT_PATH" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null
IDENTITIES="$(security find-identity -v -p codesigning "$KEYCHAIN_PATH")"
echo "$IDENTITIES" | grep -q 'Apple Distribution' || {
  echo 'Khong tim thay Apple Distribution identity kem PRIVATE KEY trong chung chi .p12' >&2; exit 2;
}
security cms -D -i "$PROVISIONING_PATH" > "$SECRET_DIR/profile.plist"
export SIGNING_METADATA="$RUNNER_TEMP/canlua_signing_metadata.txt"
python3 - <<'PY'
from pathlib import Path
import os, plistlib, datetime
info=plistlib.loads(Path(os.environ['RUNNER_TEMP']+'/canlua-signing/profile.plist').read_bytes())
profile_name=info['Name']; uuid=info['UUID']
expected_team=os.environ['APPLE_TEAM_ID']; bundle=os.environ['IOS_BUNDLE_ID']
team=info['TeamIdentifier'][0]
app=info['Entitlements']['application-identifier']
expiry=info['ExpirationDate']
if expiry.replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
    raise SystemExit('Provisioning profile da het han')
if team != expected_team: raise SystemExit('APPLE_TEAM_ID khong trung voi Team ID trong provisioning profile')
if app != f'{team}.{bundle}':
    raise SystemExit('Provisioning profile khong khop Bundle ID: '+app)
# App Store profiles have no ProvisionedDevices; ad-hoc/development profiles cannot publish to TestFlight.
if 'ProvisionedDevices' in info or info.get('ProvisionsAllDevices',False):
    raise SystemExit('Can App Store Connect distribution provisioning profile, khong dung ad-hoc/development')
if info['Entitlements'].get('get-task-allow', False):
    raise SystemExit('Profile development khong hop le cho phat hanh')
import json
Path(os.environ['SIGNING_METADATA']).write_text(json.dumps({'name':profile_name,'uuid':uuid}),encoding='utf-8')
print('Profiling hop le: team, Bundle ID, loai distribution, thoi han.')
PY
PROFILE_UUID="$(python3 -c 'import json,os;print(json.load(open(os.environ["SIGNING_METADATA"]))["uuid"])')"
cp "$PROVISIONING_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/$PROFILE_UUID.mobileprovision"
# CocoaPods depends on Xcodeproj; CI generates the iOS project fresh before this step.
export SIGNING_METADATA
ruby <<'RUBY'
require 'xcodeproj'
require 'json'
project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
profile_name = JSON.parse(File.read(ENV.fetch('SIGNING_METADATA')))['name']
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Khong tim thay Runner target' unless runner
runner.build_configurations.each do |config|
  settings = config.build_settings
  settings['DEVELOPMENT_TEAM'] = ENV.fetch('APPLE_TEAM_ID')
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = ENV.fetch('IOS_BUNDLE_ID')
  settings['CODE_SIGN_STYLE'] = 'Manual'
  settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
  settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
  settings['PROVISIONING_PROFILE_SPECIFIER'] = profile_name
end
project.save
puts 'Da cau hinh Runner target manual signing.'
RUBY
python3 <<'PY'
import os,plistlib,json
profile=json.load(open(os.environ['SIGNING_METADATA']))['name']
opts={'method':'app-store-connect','signingStyle':'manual','teamID':os.environ['APPLE_TEAM_ID'],
      'signingCertificate':'Apple Distribution','provisioningProfiles':{os.environ['IOS_BUNDLE_ID']:profile},
      'stripSwiftSymbols':True}
with open(os.environ['RUNNER_TEMP']+'/canlua_ExportOptions.plist','wb') as f:
    plistlib.dump(opts,f)
print('Da tao ExportOptions.plist cho App Store Connect.')
PY
