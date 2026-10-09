# CÂN LÚA PRO V0.5.6 – SỬA LỖI JAVA_HOME KHI BUILD APK

## Nhật ký lỗi ngày 10/10/2026

V0.5.5 hoàn thành các bước 1–6, `flutter analyze` thông báo `No issues found!` và cả 19 bài kiểm thử đạt. Bước 7 thất bại:

```
ERROR: JAVA_HOME is set to an invalid directory:
C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot
```

## Nguyên nhân và cách khắc phục

Trong lần chạy trước, biến môi trường `JAVA_HOME`/đường dẫn truyền vào lệnh Windows/Gradle có thể có dấu `\` cuối thư mục hoặc dấu nháy gây hiểu sai. V0.5.6 chuẩn hóa thư mục JDK thành đường dẫn thư mục thực tế, không có dấu nháy hay dấu `\` cuối đường dẫn, kiểm tra `bin\java.exe`, `bin\javac.exe`, và kiểm tra với `cmd.exe` trước lệnh Gradle.

Đường dẫn kỳ vọng trên máy của bạn:

```
C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot
```

Không thêm dấu nháy vào nội dung biến `JAVA_HOME`, không để dấu gạch chéo ngược `\` ở cuối. Không trỏ biến tới thư mục `bin`.

## Cập nhật bằng bản vá

1. Đóng cửa sổ BUILD đang mở.
2. Giải nén bản vá V0.5.6, chép đè `scripts\build_apk_windows.ps1` và `BUILD_APK_WINDOWS.bat` vào thư mục `CAN_LUA_PRO` của V0.5.5. Sao chép `docs\FIX_BUILD_JAVA_HOME_V056.md` nếu cần.
3. Nháy đúp `BUILD_APK_WINDOWS.bat`. Không cần xóa Flutter SDK/Android SDK đã cài.
4. Khi build thành công, file `output\CAN_LUA_PRO_ANDROID.apk` sẽ được tạo tự động.

Nếu còn lỗi, gửi lại file `output\build_*.log` mới nhất. Bản vá đã bổ sung dòng `JAVA_HOME da chuan hoa cho Gradle` để kiểm tra.

## Lưu ý

Script đã được kiểm tra tĩnh; chưa chạy thử trên Windows ở môi trường biên soạn. APK chỉ có sau khi build thành công trên máy Windows. APK phục vụ kiểm thử, chưa cấu hình chứng thư ký bản phát hành thương mại riêng.
