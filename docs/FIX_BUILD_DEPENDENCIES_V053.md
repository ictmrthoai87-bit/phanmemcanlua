# V0.5.3 - Sua loi dependency va Android SDK

## Loi trong file build_20261010_001835.log

- Flutter 3.47.7 va JDK 17 da duoc cai dat thanh cong. KHONG can tai lai.
- Buoc 3/7: Android SDK bao `Package platforms not found` va `Package build-tools not found`, tuy nhien script van tiep tuc.
- Buoc 4/7: `share_plus ^13.3.1` su dung win32 ^6, `file_picker ^11.0.3` su dung win32 ^5. Dart pub that bai ngay khi `flutter create`.
- `file_picker 11.x` doi `FilePicker.platform.pickFiles` thanh `FilePicker.pickFiles`.

## Ban sua V0.5.3

- Ghim `share_plus: 12.0.2` va `file_picker: 11.0.3` vao `pubspec.yaml` de tranh xung dot win32.
- Sua loi API `FilePicker.pickFiles()` de chuc nang khoi phuc JSON hoat dong.
- Script BUILD uu tien Android CLI voi goi `platforms/android-35`, `platforms/android-36`, `build-tools/35.0.0`, `build-tools/36.0.0` (duong dan co dau `/`).
- Sau khi cai SDK, KIEM TRA thuc te `android.jar`, `aapt2.exe`, `adb.exe` truoc khi build. Neu thieu dung lai va bao loi ro rang.
- Dung lai JDK 17 va Flutter SDK da cai trong `%%LOCALAPPDATA%%\CLB`.
- Tat ca chuc nang can lua V0.5 duoc giu nguyen. Khong co AI/OCR/QR.

## Cach cai

1. Giai nen ban va nhanh vao dung thu muc CAN_LUA_PRO V0.5.2, chap nhan GHI DE tat ca file.
2. Chay BUILD_APK_WINDOWS.bat (khong can xoa SDK hoac cai lai Java).
3. Neu thanh cong: output\CAN_LUA_PRO_ANDROID.apk.
4. Neu that bai: gui file output\build_*.log MOI NHAT (khong gui log cu).

Luu y: Tai moi truong tao ban va chua co Flutter/Android SDK de build APK thuc te, nen chua the xac nhan APK thanh cong.
