# CÂN LÚA PRO V0.5.8 – sửa lỗi cài Android NDK (Windows)

## Nguyên nhân theo log ngày 10/10/2026

Từ bản V0.5.6, Flutter Analyze không có lỗi và 19/19 phép kiểm thử đã đạt; Gradle báo:

```text
Android sdkmanager did not install NDK 28.2.13676358
Package ndk not found. Package 28.2.13676358 not found.
```

NDK r28c (28.2.13676358) là một công cụ Android khác với Android SDK Platform 36 và Build Tools 36. Trình quản lý `sdkmanager` thuộc SDK tools mới có cơ chế chuyển tiếp sang Android CLI và không cài được NDK trong phiên chạy ghi nhận ở log.

## Giải pháp

Bản V0.5.8 cài trước NDK bằng **Android CLI** với đúng tham số đường dẫn dạng dấu `/`:

```powershell
& "$env:LOCALAPPDATA\CLB\android-sdk\cmdline-tools\latest\bin\android.exe" "--sdk=$env:LOCALAPPDATA\CLB\android-sdk" sdk install 'ndk/28.2.13676358'
```

Nếu lỗi, tự động thử SDK Manager 19.0 với mã gói cũ **`ndk;28.2.13676358`**, kiểm tra `source.properties`, `ndk-build.cmd` và `clang.exe` trước khi chạy Gradle. Một thư mục NDK cài dở được **chuyển sang thư mục sao lưu** thay vì xóa trực tiếp.

NDK Windows tải xuống khá lớn (~748 MB với bản r28c chính thức); đảm bảo kết nối và ổ C đủ dung lượng để giải nén, biên dịch Gradle.

## Cập nhật không cài lại Java/Flutter

1. Giải nén `CAN_LUA_PRO_V0_5_8_BAN_VA_NDK.zip`.
2. Chép đè `scripts/build_apk_windows.ps1` và `BUILD_APK_WINDOWS.bat` trong thư mục `CAN_LUA_PRO` đang dùng.
3. Chạy `BUILD_APK_WINDOWS.bat` như trước. Khi hoàn tất, file APK nằm ở `output/CAN_LUA_PRO_ANDROID.apk`.
4. Nếu thất bại, gửi **file `output/build_*.log` mới nhất**. Không dùng file log cũ.

Bạn có thể cài NDK riêng bằng Android Studio: `Tools > SDK Manager > SDK Tools > Show Package Details > NDK (Side by side) > 28.2.13676358`. SDK đích trong log: `%LOCALAPPDATA%\CLB\android-sdk` (cần đúng SDK đang dùng).

## Trạng thái xác minh

Chỉnh sửa script và tạo gói mã nguồn thành công. Chưa có Windows/Flutter SDK trong môi trường tạo file nên chưa thể xác nhận `assembleRelease` chạy thành công hay xuất APK thực tế.

Tài liệu chính thức:
- https://developer.android.com/tools/agents/android-cli/commands/sdk_install
- https://developer.android.com/tools/sdkmanager
- https://developer.android.com/studio/projects/install-ndk
