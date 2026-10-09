# CÂN LÚA PRO V0.5.10 – SỬA LỖI ANALYZE VÀ KIỂM SOÁT BUILD

## Lỗi chính xác trong log 01:22:38 ngày 10/10/2026

- Dòng lỗi: `lib/screens/farmer_home_screen.dart:1:8 - unused_import`.
- Thư viện `dart:io` đã không còn được sử dụng ở màn hình này sau khi chuyển `file_picker` sang v12.
- `flutter analyze --no-fatal-infos` vẫn coi **warnings** là lỗi, nên BUILD dừng ở bước 6/7.
- Java 17, Flutter 3.47.7, Android API 36 và NDK r28c đã được cài thành công.
- Không có bằng chứng từ log này về thành công/thất bại của Gradle ở bước 7/7, vì Gradle chưa được chạy.

## Đã chỉnh

1. Xóa dòng `import 'dart:io';` tại `lib/screens/farmer_home_screen.dart`; giữ nguyên `dart:io` trong các dịch vụ tạo tệp thật.
2. Giữ chế độ phân tích nghiêm ngặt (`flutter analyze --fatal-infos`) thay vì bỏ qua cảnh báo để ép build.
3. Lưu `pubspec.lock` sau khi giải quyết thư viện; không tự xóa lock mỗi lần build.
4. Thêm preflight kiểm tra người dùng đã áp đúng bản vá.
5. Build xong mới sao chép APK và xác nhận kích thước tệp.
6. Pin Flutter 3.47.7 trong GitHub Actions để CI có phiên bản nhất quán.

## Cách sử dụng trên Windows

Giải nén bản vá và chép đè đúng thư mục `CAN_LUA_PRO`. Sau đó chạy:

`BUILD_APK_WINDOWS.bat`

Nếu thành công, lấy `output/CAN_LUA_PRO_ANDROID.apk`. Nếu thất bại, gửi log `output/build_*.log` mới nhất. Không cần cài lại SDK/NDK.

## Quan trọng

**Chưa biên dịch APK thật trong môi trường tạo gói này** (không có Flutter/Android SDK và không có kết nối tải SDK).
Các bước `flutter analyze`, `flutter test`, Gradle và thử cài máy thật phải chạy trên Windows của bạn hoặc CI.
Không thể bảo đảm không có lỗi Gradle/ứng dụng tiếp theo cho tới khi chạy toàn bộ chuỗi build.
