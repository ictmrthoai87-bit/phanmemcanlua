#requires -Version 5.1
# CAN LUA PRO V0.5.10 - Windows APK builder (preflight + repeatable dependencies)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$out = Join-Path $root 'output'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$log = Join-Path $out ("build_" + $stamp + '.log')
$transcriptStarted = $false
try { Start-Transcript -Path $log -Force | Out-Null; $transcriptStarted = $true }
catch { Write-Warning "Khong ghi duoc log: $_" }

function Section([string]$message) { Write-Host "`n=== $message ===" -ForegroundColor Cyan }
function Fail([string]$message) { throw $message }
function Require-Exit([string]$message) {
  if ($LASTEXITCODE -ne 0) { Fail "$message (exit code: $LASTEXITCODE)" }
}
function Get-WorkingToolsRoot {
  # Place all SDKs and build intermediates outside the user's deeply nested source folder.
  $p = Join-Path $env:LOCALAPPDATA 'CLB'
  if ($p.Length -gt 110) {
    # Windows user-profile paths can be unusually deep too.
    $p = Join-Path $env:SystemDrive 'CLB'
  }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
  return (Resolve-Path $p).Path
}
function Download-File([string]$url, [string]$destination) {
  Write-Host "Dang tai: $url"
  $folder = Split-Path $destination -Parent
  New-Item -ItemType Directory -Force -Path $folder | Out-Null
  if (Test-Path $destination) { Remove-Item -LiteralPath $destination -Force }
  if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
    try { Start-BitsTransfer -Source $url -Destination $destination -ErrorAction Stop; return }
    catch { Write-Warning 'BITS khong kha dung, chuyen sang HTTPS.'; if (Test-Path $destination) { Remove-Item $destination -Force } }
  }
  Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -MaximumRedirection 5 -TimeoutSec 1800
}
function Expand-WithTar([string]$zip, [string]$destination) {
  New-Item -ItemType Directory -Force -Path $destination | Out-Null
  $tarCmd = Get-Command tar.exe -ErrorAction SilentlyContinue
  if (-not $tarCmd) {
    Fail 'Thieu tar.exe (Windows 10/11). Vui long cap nhat Windows de co tar.exe.'
  }
  Write-Host "Dang giai nen bang tar: $zip"
  & $tarCmd.Source -xf $zip -C $destination
  Require-Exit 'Giai nen ZIP bang tar that bai. Kiem tra dung luong dia va file ZIP.'
}
function Normalize-JdkPath([string]$candidate) {
  # JAVA_HOME from Windows environment may contain literal quotes or a trailing
  # backslash. Gradle's Windows batch wrapper must receive a plain directory.
  if ([string]::IsNullOrWhiteSpace($candidate)) { return $null }
  $clean = $candidate.Trim().Trim([char[]]@('"', "'", ' '))
  $clean = $clean.TrimEnd([char[]]@('\', '/'))
  if (-not (Test-Path -LiteralPath $clean -PathType Container)) { return $null }
  try {
    $clean = (Get-Item -LiteralPath $clean -ErrorAction Stop).FullName.TrimEnd([char[]]@('\', '/'))
  } catch { return $null }
  $javaExe = Join-Path $clean 'bin\java.exe'
  $javacExe = Join-Path $clean 'bin\javac.exe'
  $release = Join-Path $clean 'release'
  if (-not (Test-Path -LiteralPath $javaExe -PathType Leaf)) { return $null }
  if (-not (Test-Path -LiteralPath $javacExe -PathType Leaf)) { return $null }
  if (-not (Test-Path -LiteralPath $release -PathType Leaf)) { return $null }
  $versionLine = Get-Content -LiteralPath $release -ErrorAction SilentlyContinue | Where-Object { $_ -match '^JAVA_VERSION=' } | Select-Object -First 1
  if ($versionLine -match '^JAVA_VERSION="(17|21)(\.|"|\+)') { return $clean }
  return $null
}
function Get-Jdk17 {
  $dirs = @()
  if ($env:JAVA_HOME) { $dirs += $env:JAVA_HOME }
  $dirs += (Join-Path $env:ProgramFiles 'Eclipse Adoptium')
  $dirs += (Join-Path $env:ProgramFiles 'Java')
  $dirs += (Join-Path $env:ProgramFiles 'Microsoft')
  $dirs += (Join-Path $env:ProgramFiles 'Android\Android Studio\jbr')
  if (${env:ProgramFiles(x86)}) { $dirs += (Join-Path ${env:ProgramFiles(x86)} 'Eclipse Adoptium') }
  foreach ($dir in $dirs) {
    if (-not $dir) { continue }
    $cleanParent = $dir.Trim().Trim([char[]]@('"', "'", ' ')).TrimEnd([char[]]@('\', '/'))
    if (-not (Test-Path -LiteralPath $cleanParent -PathType Container)) { continue }
    $candidates = @($cleanParent)
    $candidates += @(Get-ChildItem -LiteralPath $cleanParent -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    foreach ($jdkCandidateHome in $candidates) {
      $validJdk = Normalize-JdkPath $jdkCandidateHome
      if ($validJdk) { return $validJdk }
    }
  }
  return $null
}
function Assert-JavaHomeForGradle([string]$jdkHome) {
  $cleanJdk = Normalize-JdkPath $jdkHome
  if (-not $cleanJdk) { Fail 'JDK 17/21 khong hop le. Kiem tra JAVA_HOME, bin\java.exe va bin\javac.exe.' }
  # Avoid passing a quoted path or terminal backslash to gradlew.bat.
  $env:JAVA_HOME = $cleanJdk
  $env:PATH = (Join-Path $cleanJdk 'bin') + ';' + $env:PATH
  $expectedJava = Join-Path $env:JAVA_HOME 'bin\java.exe'
  if (-not (Test-Path -LiteralPath $expectedJava -PathType Leaf)) {
    Fail "Java.exe khong ton tai: $expectedJava"
  }
  # Confirm CMD.exe/Gradle also sees the directory (not just PowerShell).
  & $env:ComSpec /D /C 'if exist "%JAVA_HOME%\bin\java.exe" (exit /b 0) else (echo JAVA_HOME khong hop le trong CMD & exit /b 3)'
  Require-Exit 'Gradle/CMD khong tim thay JAVA_HOME\bin\java.exe'
  Write-Host "JAVA_HOME da chuan hoa cho Gradle: $env:JAVA_HOME" -ForegroundColor Green
  return $cleanJdk
}
function Get-FlutterPath([string]$toolsRoot, [string]$sourceRoot) {
  $localBat = Join-Path $toolsRoot 'flutter\bin\flutter.bat'
  if (Test-Path $localBat) { return $localBat }
  $installed = Get-Command flutter -ErrorAction SilentlyContinue
  if ($installed -and $installed.Source) { return $installed.Source }
  Write-Host 'Chua co Flutter SDK. Tai Flutter stable chinh thuc.'
  $index = Invoke-RestMethod -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json' -TimeoutSec 180
  $hash = $index.current_release.stable
  $release = $index.releases | Where-Object { $_.hash -eq $hash } | Select-Object -First 1
  if (-not $release -or -not $release.archive) { Fail 'Khong tim thay Flutter stable trong danh muc chinh thuc.' }
  $zip = Join-Path $toolsRoot 'flutter_sdk.zip'
  $oldZip = Join-Path $sourceRoot '.build_tools\flutter_sdk.zip'
  if (-not (Test-Path $zip) -and (Test-Path $oldZip)) {
    Write-Host 'Phat hien file Flutter da tai tu lan build truoc. Thu su dung lai.'
    Move-Item -LiteralPath $oldZip -Destination $zip -Force
  }
  $hasGoodZip = $false
  if (Test-Path $zip) {
    if ($release.sha256) {
      $digest = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
      $hasGoodZip = ($digest.ToLowerInvariant() -eq ([string]$release.sha256).ToLowerInvariant())
    } else {
      $hasGoodZip = ((Get-Item -LiteralPath $zip).Length -gt 100MB)
    }
    if (-not $hasGoodZip) { Write-Warning 'File Flutter ZIP cu sai/khong day du; tai lai.' }
  }
  if (-not $hasGoodZip) {
    Download-File ("https://storage.googleapis.com/flutter_infra_release/releases/" + $release.archive) $zip
    if ($release.sha256) {
      $digest = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
      if ($digest.ToLowerInvariant() -ne ([string]$release.sha256).ToLowerInvariant()) {
        Fail 'SHA256 cua Flutter SDK khong dung. Dung build de bao ve an toan.'
      }
    }
  }
  $unpack = Join-Path $toolsRoot 'flutter_unpacked'
  if (Test-Path $unpack) { Remove-Item -LiteralPath $unpack -Recurse -Force }
  Expand-WithTar $zip $unpack
  $extracted = Join-Path $unpack 'flutter'
  if (-not (Test-Path (Join-Path $extracted 'bin\flutter.bat'))) {
    Fail 'ZIP da giai nen nhung thieu flutter\bin\flutter.bat. Khong tiep tuc.'
  }
  $target = Join-Path $toolsRoot 'flutter'
  if (Test-Path $target) { Remove-Item -LiteralPath $target -Recurse -Force }
  Move-Item -LiteralPath $extracted -Destination $target
  Remove-Item -LiteralPath $unpack -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
  return (Join-Path $target 'bin\flutter.bat')
}
function Prepare-AndroidSdk([string]$toolsRoot) {
  $defaultSdk = Join-Path $toolsRoot 'android-sdk'
  $candidates = @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, (Join-Path $env:LOCALAPPDATA 'Android\Sdk'), $defaultSdk)
  $sdk = $null
  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) { $sdk = (Resolve-Path $candidate).Path; break }
  }
  if (-not $sdk) { $sdk = $defaultSdk }
  New-Item -ItemType Directory -Force -Path $sdk | Out-Null
  $sdkManager = Join-Path $sdk 'cmdline-tools\latest\bin\sdkmanager.bat'
  if (-not (Test-Path $sdkManager)) {
    Write-Host 'Dang tai Android SDK command-line tools chinh thuc.'
    [xml]$xml = (Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/repository2-1.xml' -UseBasicParsing -TimeoutSec 180).Content
    $packages = $xml.SelectNodes("//*[local-name()='remotePackage']")
    $pkg = $packages | Where-Object { $_.GetAttribute('path') -eq 'cmdline-tools;latest' } | Select-Object -First 1
    if (-not $pkg) { Fail 'Khong tim thay cmdline-tools;latest trong Android repository.' }
    $arcs = $pkg.SelectNodes("./*[local-name()='archives']/*[local-name()='archive']")
    $winArc = $arcs | Where-Object {
      $hostOsNode = $_.SelectSingleNode("./*[local-name()='host-os']")
      $hostOsNode -and $hostOsNode.InnerText -eq 'windows'
    } | Select-Object -First 1
    if (-not $winArc) { Fail 'Khong tim thay command-line tools cho Windows.' }
    $urlNode = $winArc.SelectSingleNode(".//*[local-name()='complete']/*[local-name()='url']")
    $checksumNode = $winArc.SelectSingleNode(".//*[local-name()='complete']/*[local-name()='checksum']")
    if (-not $urlNode) { Fail 'Thieu URL Android tools trong catalog.' }
    $zip = Join-Path $toolsRoot 'android_cmdline.zip'
    Download-File ('https://dl.google.com/android/repository/' + $urlNode.InnerText) $zip
    if ($checksumNode -and $checksumNode.GetAttribute('type') -eq 'sha256') {
      $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
      if ($actual -ne $checksumNode.InnerText.Trim().ToLowerInvariant()) { Fail 'SHA256 Android tools khong dung.' }
    }
    $unpack = Join-Path $toolsRoot 'android_cmdline_unpacked'
    if (Test-Path $unpack) { Remove-Item -LiteralPath $unpack -Recurse -Force }
    Expand-WithTar $zip $unpack
    $extracted = Join-Path $unpack 'cmdline-tools'
    if (-not (Test-Path (Join-Path $extracted 'bin\sdkmanager.bat'))) { Fail 'Android cmdline-tools ZIP sai cau truc.' }
    $parent = Join-Path $sdk 'cmdline-tools'
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $target = Join-Path $parent 'latest'
    if (Test-Path $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    Move-Item -LiteralPath $extracted -Destination $target
    Remove-Item -LiteralPath $unpack -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
  }
  if (-not (Test-Path $sdkManager)) { Fail 'Khong tim thay sdkmanager.bat sau khi cai dat.' }
  return @{ sdk = $sdk; manager = $sdkManager }
}
function Test-AndroidPackages([string]$sdk, [switch]$ShowMissing) {
  # Flutter 3.47 uses Android API 36 on this project. Android API 35 is not needed to build this APK.
  $paths = @(
    (Join-Path $sdk 'platform-tools\adb.exe'),
    (Join-Path $sdk 'platforms\android-36\android.jar'),
    (Join-Path $sdk 'build-tools\36.0.0\aapt2.exe'),
    (Join-Path $sdk 'build-tools\36.0.0\apksigner.bat')
  )
  $missing = @($paths | Where-Object { -not (Test-Path -LiteralPath $_) })
  if ($missing.Count -gt 0 -and $ShowMissing) {
    Write-Host 'Android SDK con thieu:' -ForegroundColor Yellow
    foreach ($filePath in $missing) { Write-Host " - $filePath" -ForegroundColor Yellow }
  }
  return ($missing.Count -eq 0)
}
function Install-AndroidSdkFallback([string]$sdk, [string]$toolsRoot) {
  # The cmdline-tools 'latest' in October 2026 contains a deprecated wrapper around
  # Android CLI. This version-19 SDK manager predates the wrapper and is predictable.
  $oldManager = Join-Path $sdk 'cmdline-tools\19.0\bin\sdkmanager.bat'
  if (-not (Test-Path -LiteralPath $oldManager)) {
    $archive = Join-Path $toolsRoot 'android_cmdline_19_windows.zip'
    $officialUrl = 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip'
    $expectedSha = '98b565cb657b012dae6794cefc0f66ae1efb4690c699b78a614b4a6a3505b003'
    $valid = $false
    if (Test-Path -LiteralPath $archive) {
      $valid = ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -eq $expectedSha)
    }
    if (-not $valid) { Download-File $officialUrl $archive }
    $actualSha = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha -ne $expectedSha) {
      Fail 'Bo Android SDK cmdline-tools 19.0 sai SHA256. Dung lai vi an toan.'
    }
    $unpack = Join-Path $toolsRoot 'android_cmdline_19_unpacked'
    if (Test-Path $unpack) { Remove-Item -LiteralPath $unpack -Recurse -Force }
    Expand-WithTar $archive $unpack
    $extracted = Join-Path $unpack 'cmdline-tools'
    if (-not (Test-Path (Join-Path $extracted 'bin\sdkmanager.bat'))) {
      Fail 'Khong the tim thay SDK manager 19 trong ZIP.'
    }
    $versionFolder = Join-Path $sdk 'cmdline-tools\19.0'
    New-Item -ItemType Directory -Path (Split-Path $versionFolder -Parent) -Force | Out-Null
    if (Test-Path $versionFolder) { Remove-Item -LiteralPath $versionFolder -Recurse -Force }
    Move-Item -LiteralPath $extracted -Destination $versionFolder
    Remove-Item -LiteralPath $unpack -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host 'Da cai Android SDK Manager 19.0 tai thu muc rieng, khong xoa cmdline-tools latest.'
  }
  Write-Host 'Su dung SDK Manager 19.0 de cai SDK. Neu hoi license, doc va nhap y neu dong y.'
  # Keep semicolon-delimited legacy package identifiers as quoted single arguments.
  & $oldManager "--sdk_root=$sdk" --licenses
  if ($LASTEXITCODE -ne 0) { Fail 'Chua hoan thanh chap nhan Android SDK licenses.' }
  & $oldManager "--sdk_root=$sdk" 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0'
  if ($LASTEXITCODE -ne 0) { Fail "SDK Manager 19.0 cai dat that bai (exit code: $LASTEXITCODE)" }
}

# NDK r28c is required by Flutter 3.47.7's Android Gradle configuration.
function Test-AndroidNdk([string]$sdk, [string]$ndkVersion, [switch]$ShowMissing) {
  $ndkHome = Join-Path (Join-Path $sdk 'ndk') $ndkVersion
  $props = Join-Path $ndkHome 'source.properties'
  $required = @(
    $props,
    (Join-Path $ndkHome 'ndk-build.cmd'),
    (Join-Path $ndkHome 'toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe')
  )
  $missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
  if ($missing.Count -eq 0) {
    $rev = Get-Content -LiteralPath $props -ErrorAction SilentlyContinue | Where-Object { $_ -match '^\s*Pkg\.Revision\s*=' } | Select-Object -First 1
    $expected = '^\s*Pkg\.Revision\s*=\s*' + [regex]::Escape($ndkVersion) + '\s*$'
    if (-not $rev -or $rev -notmatch $expected) { $missing += "source.properties Pkg.Revision phai bang $ndkVersion" }
  }
  if ($ShowMissing -and $missing.Count -gt 0) {
    Write-Host "NDK $ndkVersion chua day du:" -ForegroundColor Yellow
    foreach ($missingPath in $missing) { Write-Host " - $missingPath" -ForegroundColor Yellow }
  }
  return ($missing.Count -eq 0)
}
function Ensure-AndroidNdk([string]$sdk, [string]$toolsRoot, [string]$ndkVersion) {
  if (Test-AndroidNdk $sdk $ndkVersion) {
    Write-Host "Android NDK OK: $ndkVersion (su dung lai ban da cai)." -ForegroundColor Green
    return
  }
  Write-Host "Can Android NDK $ndkVersion. Dang chuan bi cai dat truoc Gradle." -ForegroundColor Cyan
  $ndkHome = Join-Path (Join-Path $sdk 'ndk') $ndkVersion
  if (Test-Path -LiteralPath $ndkHome) {
    # Preserve a corrupt/incomplete installation instead of deleting user's files.
    $backup = Join-Path $toolsRoot ("ndk_incomplete_" + $ndkVersion + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    try {
      Move-Item -LiteralPath $ndkHome -Destination $backup -ErrorAction Stop
      Write-Host "Da chuyen NDK cai do sang: $backup"
    } catch {
      Fail "Khong the di chuyen thu muc NDK cai do $ndkHome. Dong Gradle/Android Studio va chay lai. Chi tiet: $_"
    }
  }
  $androidCli = $null
  foreach ($possible in @(
    (Join-Path $sdk 'cmdline-tools\latest\bin\android.exe'),
    (Join-Path $sdk 'cmdline-tools\latest\bin\android.bat')
  )) {
    if (Test-Path -LiteralPath $possible -PathType Leaf) { $androidCli = $possible; break }
  }
  if ($androidCli) {
    Write-Host "Cai NDK bang Android CLI: android sdk install ndk/$ndkVersion"
    & $androidCli "--sdk=$sdk" sdk install "ndk/$ndkVersion"
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Android CLI loi (exit code $LASTEXITCODE). Se thu SDK Manager 19.0."
    }
  } else {
    Write-Warning 'Thieu android.exe trong cmdline-tools/latest; se dung SDK Manager 19.0.'
  }
  if (-not (Test-AndroidNdk $sdk $ndkVersion)) {
    Write-Host 'Dang thu bo cai NDK du phong bang SDK Manager 19.0.' -ForegroundColor Yellow
    # A failed Android CLI attempt can leave a partial version folder, which
    # may confuse the legacy SDK manager. Quarantine it before the retry.
    if (Test-Path -LiteralPath $ndkHome) {
      $retryBackup = Join-Path $toolsRoot ("ndk_incomplete_retry_" + $ndkVersion + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
      try { Move-Item -LiteralPath $ndkHome -Destination $retryBackup -ErrorAction Stop }
      catch { Fail "Khong the di chuyen NDK cai do de thu lai SDK Manager: $_" }
      Write-Host "Da luu thu muc NDK cai do: $retryBackup"
    }
    $oldManager = Join-Path $sdk 'cmdline-tools\19.0\bin\sdkmanager.bat'
    if (-not (Test-Path -LiteralPath $oldManager)) {
      Install-AndroidSdkFallback $sdk $toolsRoot
    }
    if (-not (Test-Path -LiteralPath $oldManager)) {
      Fail 'Khong the tao SDK Manager 19.0 de cai NDK.'
    }
    & $oldManager "--sdk_root=$sdk" '--install' ("ndk;" + $ndkVersion)
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "SDK Manager 19.0 cai NDK loi (exit code $LASTEXITCODE)."
    }
  }
  if (-not (Test-AndroidNdk $sdk $ndkVersion -ShowMissing)) {
    Fail "Khong the cai NDK $ndkVersion. Kiem tra ket noi dl.google.com, dung luong dia (NDK rat lon) va log. Khong chay Gradle voi SDK thieu NDK."
  }
  Write-Host "Android NDK $ndkVersion OK. Da xac nhan source.properties, ndk-build.cmd, clang.exe." -ForegroundColor Green
}

function Prepare-Project([string]$sourceRoot, [string]$toolsRoot) {
  $workspace = Join-Path $toolsRoot 'project'
  if (Test-Path $workspace) { Remove-Item -LiteralPath $workspace -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $workspace | Out-Null
  foreach ($file in @('pubspec.yaml','pubspec.lock','analysis_options.yaml')) {
    $p = Join-Path $sourceRoot $file
    if (Test-Path $p) { Copy-Item -LiteralPath $p -Destination (Join-Path $workspace $file) -Force }
  }
  foreach ($folder in @('lib','test','assets','fonts')) {
    $p = Join-Path $sourceRoot $folder
    if (Test-Path $p) { Copy-Item -LiteralPath $p -Destination $workspace -Recurse -Force }
  }
  if (-not (Test-Path (Join-Path $workspace 'lib\main.dart'))) { Fail 'Thieu lib\main.dart. Giai nen day du bo ma nguon.' }
  return $workspace
}

try {
  $tools = Get-WorkingToolsRoot
  Section '1/7 - Kiem tra Git va JDK 17'
  Write-Host "Thu muc cong cu ngan: $tools"
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $gitCmd = Join-Path $env:ProgramFiles 'Git\cmd'
    if (Test-Path (Join-Path $gitCmd 'git.exe')) { $env:PATH = $gitCmd + ';' + $env:PATH }
  }
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
      & winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
      $gitCmd = Join-Path $env:ProgramFiles 'Git\cmd'
      if (Test-Path (Join-Path $gitCmd 'git.exe')) { $env:PATH = $gitCmd + ';' + $env:PATH }
    }
  }
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 'Thieu Git. Cai Git for Windows, sau do chay lai.' }
  $jdk = Get-Jdk17
  if (-not $jdk) {
    Write-Host 'Java hien tai co the la Java 25. Can JDK 17 hoac 21 cho Gradle.'
    if (Get-Command winget -ErrorAction SilentlyContinue) {
      & winget install --id EclipseAdoptium.Temurin.17.JDK -e --silent --accept-source-agreements --accept-package-agreements
    }
    $jdk = Get-Jdk17
  }
  if (-not $jdk) { Fail 'Chua tim thay JDK 17/21. Cai Temurin JDK 17 va chay lai BUILD.' }
  $jdk = Assert-JavaHomeForGradle $jdk
  Write-Host "JDK duoc su dung: $jdk"
  & (Join-Path $jdk 'bin\java.exe') -version
  Require-Exit 'Khong chay duoc Java'

  Section '2/7 - Flutter SDK (giai nen vao thu muc ngan)'
  $flutter = Get-FlutterPath $tools $root
  & $flutter --version
  Require-Exit 'Flutter SDK khong hoat dong'
  & $flutter config "--jdk-dir=$jdk"
  Require-Exit 'Flutter khong nhan JDK'

  Section '3/7 - Android SDK'
  $android = Prepare-AndroidSdk $tools
  $env:ANDROID_SDK_ROOT = $android.sdk
  $env:ANDROID_HOME = $android.sdk
  & $flutter config --android-sdk $android.sdk
  Require-Exit 'Flutter khong nhan Android SDK'
  # Check actual SDK files rather than trusting a zero exit code of an installer.
  if (-not (Test-AndroidPackages $android.sdk)) {
    $androidExe = Join-Path $android.sdk 'cmdline-tools\latest\bin\android.exe'
    $androidBat = Join-Path $android.sdk 'cmdline-tools\latest\bin\android.bat'
    $androidCli = $null
    if (Test-Path -LiteralPath $androidExe) { $androidCli = $androidExe }
    elseif (Test-Path -LiteralPath $androidBat) { $androidCli = $androidBat }
    if ($androidCli) {
      Write-Host "Dang cai Android SDK voi Android CLI truc tiep: $androidCli"
      # Android CLI expects paths with slashes, not legacy semicolons.
      & $androidCli "--sdk=$($android.sdk)" sdk install 'platform-tools' 'platforms/android-36' 'build-tools/36.0.0'
      if ($LASTEXITCODE -ne 0) {
        Write-Warning "Android CLI tra ma $LASTEXITCODE. Thu SDK Manager 19.0 neu can."
      }
    } else {
      Write-Warning 'Khong tim thay android.exe hay android.bat. Chuyen sang SDK Manager 19.0.'
    }
  }
  if (-not (Test-AndroidPackages $android.sdk)) {
    Test-AndroidPackages $android.sdk -ShowMissing | Out-Null
    Write-Host 'Thu cong cu cai SDK du phong, khong can cai lai Flutter/JDK.' -ForegroundColor Yellow
    Install-AndroidSdkFallback $android.sdk $tools
  }
  if (-not (Test-AndroidPackages $android.sdk -ShowMissing)) {
    Fail 'Android SDK van thieu sau khi da thu ca 2 cach. Hay xem output\build_*.log.'
  }
  Write-Host 'Android SDK OK: platform-tools, Android API 36, build-tools 36.0.0.' -ForegroundColor Green
  # Flutter 3.47.7 uses NDK r28c; Gradle's deprecated sdkmanager wrapper fails to auto-install it.
  Ensure-AndroidNdk $android.sdk $tools '28.2.13676358'
  Section '4/7 - Tao project Android trong duong dan ngan'
  $workspace = Prepare-Project $root $tools
  $screenPath = Join-Path $workspace 'lib\screens\farmer_home_screen.dart'
  $screenCode = [System.IO.File]::ReadAllText($screenPath)
  if ($screenCode -match '(?m)^\s*import\s+[\x22\x27]dart:io[\x22\x27]\s*;') {
    Fail 'Ban cu con import dart:io trong farmer_home_screen.dart. Chep dung patch V0.5.10 de tranh canh bao analyzer.'
  }
  Set-Location $workspace
  & $flutter create --platforms=android --org vn.canlua .
  Require-Exit 'flutter create that bai'
  # Flutter creates the default widget_test.dart referencing MyApp when no custom test
  # was present. Our root class is LuaCanProApp; always restore the maintained test.
  $sourceWidgetTest = Join-Path $root 'test\widget_test.dart'
  $workspaceWidgetTest = Join-Path $workspace 'test\widget_test.dart'
  if (Test-Path -LiteralPath $sourceWidgetTest) {
    Copy-Item -LiteralPath $sourceWidgetTest -Destination $workspaceWidgetTest -Force
    Write-Host 'Da cap nhat bai kiem thu dung lop LuaCanProApp.'
  } elseif (Test-Path -LiteralPath $workspaceWidgetTest) {
    $widgetText = [System.IO.File]::ReadAllText($workspaceWidgetTest)
    if ($widgetText -match '\bMyApp\s*\(') {
      Remove-Item -LiteralPath $workspaceWidgetTest -Force
      Write-Host 'Da xoa bai kiem thu mac dinh MyApp khong thuoc du an.'
    }
  }
  $manifest = Join-Path $workspace 'android\app\src\main\AndroidManifest.xml'
  if (-not (Test-Path $manifest)) { Fail 'Khong tim thay AndroidManifest.xml' }
  $xmlText = [System.IO.File]::ReadAllText($manifest)
  $xmlText = [regex]::Replace($xmlText, '(?m)^\s*<uses-permission\s+[^>]*android:name="android\.permission\.CAMERA"[^>]*/>\s*', "`r`n")
  $xmlText = [regex]::Replace($xmlText, 'android:label="[^"]*"', 'android:label="Cân Lúa Pro"', 1)
  [System.IO.File]::WriteAllText($manifest, $xmlText, (New-Object System.Text.UTF8Encoding($false)))

  Section '5/7 - Cai dat thu vien Flutter'
  # Keep pubspec.lock between runs. This reduces unexpected dependency drift.
  # Flutter pub get will update an incompatible lock itself if pubspec changes.
  & $flutter pub get
  Require-Exit 'flutter pub get that bai'
  $resolvedLock = Join-Path $workspace 'pubspec.lock'
  if (-not (Test-Path -LiteralPath $resolvedLock -PathType Leaf)) {
    Fail 'Flutter pub get khong tao pubspec.lock. Khong build voi dependencies khong ro.'
  }
  Copy-Item -LiteralPath $resolvedLock -Destination (Join-Path $root 'pubspec.lock') -Force
  Write-Host 'Da luu pubspec.lock de co dinh phien ban thu vien o cac lan build tiep theo.'

  Section '6/7 - Phan tich va kiem thu'
  & $flutter analyze --fatal-infos
  Require-Exit 'flutter analyze that bai'
  & $flutter test
  Require-Exit 'flutter test that bai'

  Section '7/7 - Build APK release'
  # Revalidate before Gradle: legacy environment variables can be reintroduced by tools.
  $jdk = Assert-JavaHomeForGradle $jdk
  if (-not (Test-AndroidNdk $android.sdk '28.2.13676358' -ShowMissing)) { Fail 'Android NDK bi thieu truoc build Gradle.' }
  & $flutter build apk --release
  Require-Exit 'flutter build apk that bai'
  $apk = Join-Path $workspace 'build\app\outputs\flutter-apk\app-release.apk'
  if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { Fail 'Khong tim thay APK sau build' }
  $apkInfo = Get-Item -LiteralPath $apk
  if ($apkInfo.Length -lt 500KB) { Fail 'APK qua nho, co the bi loi hoac khong day du.' }
  $target = Join-Path $out 'CAN_LUA_PRO_ANDROID.apk'
  Copy-Item -LiteralPath $apk -Destination $target -Force
  if ((Get-Item -LiteralPath $target).Length -ne $apkInfo.Length) {
    Fail 'APK sao chep khong du so byte. Kiem tra dung luong dia.'
  }
  $sha = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
  Set-Content -LiteralPath (Join-Path $out 'CAN_LUA_PRO_ANDROID.sha256.txt') -Value "$sha *CAN_LUA_PRO_ANDROID.apk" -Encoding ASCII
  Write-Host "`nAPK DA TAO: $target" -ForegroundColor Green
  Write-Host "SHA256: $sha"
  Write-Warning 'APK thu nghiem: de phat hanh thuong mai can tao keystore rieng.'
  exit 0
}
catch {
  Write-Host "`nBUILD THAT BAI: $_" -ForegroundColor Red
  Write-Host "Xem log: $log"
  exit 1
}
finally {
  Set-Location $root
  if ($transcriptStarted) { try { Stop-Transcript | Out-Null } catch {} }
}
