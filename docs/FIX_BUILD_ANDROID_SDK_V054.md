# CÂN LÚA PRO V0.5.4 – SỬA LỖI ANDROID SDK

## Lỗi trong log 00:35:38

Lần build V0.5.3 đã cài Java 17 và Flutter 3.47.7 thành công. Ở bước 3, script chỉ kiểm tra `android.bat` mà chưa tìm `android.exe`, nên gọi `sdkmanager` tương thích ngược rồi báo `Package platforms not found`, `Package build-tools not found`.

## V0.5.4 sửa gì?

1. Ưu tiên Android CLI mới `cmdline-tools\latest\bin\android.exe` (hoặc `.bat`) với tên gói chính thức `platforms/android-36` và `build-tools/36.0.0`.
2. Nếu Android CLI lỗi hoặc chưa cài đủ, tự tải **Android SDK Command-line Tools 19.0** trực tiếp từ Google, kiểm SHA-256 trước khi giải nén, cài SDK bằng `sdkmanager` 19.0 trong thư mục riêng. Không xóa bản `latest`.
3. Chỉ yêu cầu Android SDK Platform 36, Build Tools 36.0.0 và platform-tools cho bước này. Kiểm tra tệp `android.jar`, `aapt2.exe`, `apksigner.bat`, `adb.exe` thực sự tồn tại.
4. Sửa `BUILD_APK_WINDOWS.bat` thành ANSI/ASCII không BOM để tránh lỗi `'∩╗┐@echo'`.
5. Dùng lại JDK 17/Flutter đã cài tại `%LOCALAPPDATA%\CLB`.

## Cách dùng

- Chép đè `BUILD_APK_WINDOWS.bat` và `scripts\build_apk_windows.ps1` vào thư mục `CAN_LUA_PRO` hiện có (đúng đường dẫn, không lồng thư mục).
- Nhấn đôi `BUILD_APK_WINDOWS.bat`. Nếu SDK Manager yêu cầu chấp nhận điều khoản, hãy đọc và nhập `y` nếu bạn đồng ý. Cần kết nối Internet.
- Khi hoàn tất sẽ có `output\CAN_LUA_PRO_ANDROID.apk`. Nếu lỗi, gửi file `output\build_*.log` mới nhất.

Không cần xóa SDK, cài lại Java/Flutter, hoặc thay đổi dữ liệu đã cân.

## Lưu ý

Bản vá đã qua kiểm tra tĩnh và kiểm tra ZIP trên Linux. Chưa chạy thử toàn bộ lệnh tải/cài Android SDK hoặc build APK trên máy Windows.
