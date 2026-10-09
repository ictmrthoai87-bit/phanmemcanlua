# On Windows create private key + CSR, package Apple Distribution .cer into P12,
# or generate Base64 secrets for GitHub Actions. Private keys NEVER uploaded here.
param([ValidateSet('csr','p12','base64','api-key')][string]$Action = 'csr')
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$SecDir = Join-Path $ProjectRoot 'APPLE_SECRET_LOCAL_ONLY'
New-Item -ItemType Directory -Force -Path $SecDir | Out-Null
function OpenSSLExe {
  $found = Get-Command openssl.exe -ErrorAction SilentlyContinue
  if ($found) { return $found.Source }
  $options = @('C:\Program Files\Git\usr\bin\openssl.exe', 'C:\Program Files\OpenSSL-Win64\bin\openssl.exe', 'C:\Program Files\Git\mingw64\bin\openssl.exe')
  foreach ($option in $options) { if (Test-Path $option) { return $option } }
  throw 'Khong tim thay OpenSSL. Cai Git for Windows hoac OpenSSL.'
}
function B64File([string]$Path, [string]$Target) {
  if (!(Test-Path -LiteralPath $Path)) { throw "Khong tim thay file: $Path" }
  [IO.File]::WriteAllText($Target,[Convert]::ToBase64String([IO.File]::ReadAllBytes($Path)),[Text.Encoding]::ASCII)
}
$OpenSsl = OpenSSLExe
switch ($Action) {
  'csr' {
    $key = Join-Path $SecDir 'canlua_apple_distribution_PRIVATE.key'
    $csr = Join-Path $SecDir 'canlua_apple_distribution.csr'
    if (Test-Path $key) { throw 'PRIVATE key da ton tai. Khong ghi de. Sao luu truoc va xoa thu cong neu muon tao khoa moi.' }
    & $OpenSsl req -new -newkey rsa:2048 -nodes -keyout $key -out $csr -subj '/CN=Can Lua Pro iOS Distribution/O=Le Ngoc Thoai/C=VN'
    if ($LASTEXITCODE -ne 0) { throw 'Loi tao CSR' }
    Write-Host "CSR: $csr"; Write-Host 'Tai CSR len Apple Developer > Certificates > Create Apple Distribution.'
    Write-Host 'Giu ky file PRIVATE.key, KHONG dua len GitHub.'
  }
  'p12' {
    $key = Join-Path $SecDir 'canlua_apple_distribution_PRIVATE.key'
    if (!(Test-Path $key)) { throw 'Khong co PRIVATE.key. Chay lua chon 1 (csr) truoc.' }
    $cer = Read-Host 'Nhap duong dan file Apple Distribution .cer da tai tu Apple Developer (keo file vao day)'
    $cer = $cer.Trim('"').Trim("'")
    if (!(Test-Path -LiteralPath $cer)) { throw 'Khong tim thay chung chi .cer' }
    $pem = Join-Path $SecDir 'apple_distribution.pem'
    & $OpenSsl x509 -inform DER -in $cer -out $pem
    if ($LASTEXITCODE -ne 0) {
      & $OpenSsl x509 -inform PEM -in $cer -out $pem
      if ($LASTEXITCODE -ne 0) { throw 'Apple certificate khong phai DER/PEM hop le' }
    }
    $pass1 = Read-Host 'Mat khau bao ve file P12' -AsSecureString
    $pass2 = Read-Host 'Nhap lai mat khau P12' -AsSecureString
    $plain1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass1))
    $plain2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass2))
    if ($plain1.Length -lt 12 -or $plain1 -cne $plain2) { throw 'Mat khau khong trung hoac qua ngan (toi thieu 12 ky tu)' }
    $env:CANLUA_P12_PASS = $plain1
    $p12 = Join-Path $SecDir 'CanLuaPro_AppleDistribution.p12'
    try {
      & $OpenSsl pkcs12 -export -inkey $key -in $pem -out $p12 -name 'Can Lua Pro Apple Distribution' -passout env:CANLUA_P12_PASS
      if ($LASTEXITCODE -ne 0) { throw 'Loi dong goi P12; certificate khong khop private key?' }
    } finally { Remove-Item Env:\CANLUA_P12_PASS -ErrorAction SilentlyContinue; $plain1 = $null; $plain2 = $null }
    Write-Host "File P12 da tao: $p12"; Write-Host 'Luu mat khau P12 de tao GitHub Secret P12_PASSWORD.'
  }
  'base64' {
    $p12 = Join-Path $SecDir 'CanLuaPro_AppleDistribution.p12'
    $profile = Read-Host 'Nhap duong dan App Store Connect provisioning profile .mobileprovision'
    $profile = $profile.Trim('"').Trim("'")
    B64File $p12 (Join-Path $SecDir 'BUILD_CERTIFICATE_BASE64.txt')
    B64File $profile (Join-Path $SecDir 'BUILD_PROVISION_PROFILE_BASE64.txt')
    Write-Host 'Da tao BUILD_CERTIFICATE_BASE64.txt va BUILD_PROVISION_PROFILE_BASE64.txt.'
    Write-Host 'Mo GitHub > Repo > Settings > Secrets and variables > Actions > New repository secret.'
    Write-Host 'KHONG commit cac file trong APPLE_SECRET_LOCAL_ONLY len GitHub.'
  }
  'api-key' {
    $keyfile = Read-Host 'Nhap duong dan AuthKey_XXXX.p8 (App Store Connect API)'
    $keyfile = $keyfile.Trim('"').Trim("'")
    B64File $keyfile (Join-Path $SecDir 'APPLE_API_PRIVATE_KEY_BASE64.txt')
    Write-Host 'Da tao APPLE_API_PRIVATE_KEY_BASE64.txt; chi can neu muon tu dong tai IPA len TestFlight.'
  }
}
