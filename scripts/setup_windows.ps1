$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error 'Chua cai Flutter SDK hoac Flutter chua nam trong PATH. Xem README.md.'
  exit 1
}
flutter create --platforms=android,ios --org vn.canlua .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python scripts/configure_platforms.py
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'Hoan tat. Ket noi Android va chay: flutter run'
Write-Host 'Tao APK: flutter build apk --release'
Write-Host 'Tao iOS can may Mac: xem README.md.'
