@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title CAN LUA PRO - Apple Signing Windows
:MENU
echo.
echo ============================
echo  CHUAN BI CHUNG CHI APPLE
 echo ============================
echo 1 - Tao private key va CSR tren Windows
echo 2 - Tao file Apple Distribution .p12 tu .cer cua Apple
echo 3 - Tao Base64 P12 va provisioning profile cho GitHub Secrets
echo 4 - Tao Base64 API Key .p8 (neu upload TestFlight)
echo 0 - Thoat
set /p CHOICE=Chon so: 
if "%CHOICE%"=="0" exit /b 0
if "%CHOICE%"=="1" set "MODE=csr"
if "%CHOICE%"=="2" set "MODE=p12"
if "%CHOICE%"=="3" set "MODE=base64"
if "%CHOICE%"=="4" set "MODE=api-key"
if not defined MODE goto MENU
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\apple_cert_windows.ps1" -Action "%MODE%"
if errorlevel 1 echo LOI: Doc thong bao tren va thu lai.
set "MODE="
pause
goto MENU
