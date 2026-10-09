@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title CAN LUA PRO - BUILD APK ANDROID - V0.5.10
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build_apk_windows.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" (
  echo [THANH CONG] Mo thu muc output de lay file CAN_LUA_PRO_ANDROID.apk
  if exist "%~dp0output\CAN_LUA_PRO_ANDROID.apk" explorer.exe "%~dp0output"
) else (
  echo [BUILD THAT BAI] Xem output\build_*.log va docs\FIX_BUILD_V0510.md
)
echo.
pause
exit /b %RESULT%
