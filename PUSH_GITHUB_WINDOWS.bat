@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title CAN LUA PRO - TAI MA NGUON LEN GITHUB
where git >nul 2>nul
if errorlevel 1 (
  echo CHUA CAI GIT. Vui long cai Git for Windows: https://git-scm.com/downloads/win
  goto error
)
if not exist .git git init
if errorlevel 1 goto error
git branch -M main
if errorlevel 1 goto error
git remote get-url origin >nul 2>nul
if errorlevel 1 git remote add origin https://github.com/ictmrthoai87-bit/phanmemcanlua.git
git add .
if errorlevel 1 goto error
git diff --cached --quiet
if errorlevel 1 (
  git -c user.name="Can Lua Pro" -c user.email="build@users.noreply.github.com" commit -m "Can Lua Pro - Flutter app and APK build"
  if errorlevel 1 goto error
)
git push -u origin main
if errorlevel 1 goto error
echo.
echo DA TAI MA NGUON. Vao GitHub Actions de lay APK:
echo https://github.com/ictmrthoai87-bit/phanmemcanlua/actions
echo.
pause
exit /b 0
:error
echo.
echo CO LOI. Kiem tra Git, tai khoan GitHub, quyen ghi repo va ket noi mang.
echo Neu GitHub repo da co commit, can pull va giai quyet truoc khi push.
pause
exit /b 1
