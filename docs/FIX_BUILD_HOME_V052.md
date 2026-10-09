# CAN LUA PRO - HOTFIX BUILD V0.5.2 (PowerShell HOME)

## Nguyen nhan
Windows PowerShell 5.1 co bien tu dong `$HOME` la read-only. PowerShell khong phan biet HOA / thuong, vi the lenh `foreach ($home in $candidates)` trong ham Get-Jdk17 gay loi `Cannot overwrite variable HOME because it is read-only or constant`.

## Cach cap nhat (khong can cai lai phan mem)
1. Tat cua so BUILD dang mo.
2. Giai nen file ZIP ban va vao thu muc `CAN_LUA_PRO`, cho phep ghi de file trung ten. Chu y: sau khi chep, can co `CAN_LUA_PRO\scripts\build_apk_windows.ps1`.
3. Nhan dup `BUILD_APK_WINDOWS.bat`.
4. Neu thanh cong, lay `CAN_LUA_PRO\output\CAN_LUA_PRO_ANDROID.apk` de cai tren Android.
5. Neu van loi, gui file `.log` moi nhat trong `CAN_LUA_PRO\output`.

## Noi dung sua
- Doi bien vong lap `$home` thanh `$jdkCandidateHome` trong ham Get-Jdk17, gom moi cho su dung.
- Ra soat bien dac biet `$HOME`, `$Host` trong script build.
- Khong thay doi cac phep tinh can, tru bi, co so du lieu hay tinh nang ung dung.

## Luu y
Ban va chi sua loi dung o buoc 1/7. Chua kiem thu duoc toan bo qua trinh Flutter/Android build tren Windows thuc te. Khong xoa `.build_tools`, du lieu cua phan mem, hoac JDK da cai.
