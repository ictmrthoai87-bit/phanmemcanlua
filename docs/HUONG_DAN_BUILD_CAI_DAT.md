# Hướng dẫn tạo file cài đặt trực tiếp (Android APK, iOS IPA)

Bản mã nguồn này **chưa kèm file APK/IPA được biên dịch**. Khi build thành công, file APK được đưa vào thư mục `output`. Việc biên dịch yêu cầu Flutter/Android SDK (trên PC) hoặc GitHub Actions; không thể đổi đuôi `.zip` thành `.apk`.

## A. Cách đơn giản nhất trên Windows – BUILD_APK_WINDOWS.bat

1. Giải nén ZIP vào thư mục ngắn, không có ký tự lạ, ví dụ `C:\CAN_LUA_PRO`.
2. Máy tính Windows 10/11, có internet, dung lượng trống đủ tải SDK/Android packages, có **JDK 17 hoặc 21** (Java 25 cần chuyển về JDK tương thích). Nếu chưa cài JDK, có thể cài Android Studio (https://developer.android.com/studio); lần đầu mở Android Studio sẽ có bước thiết lập.
3. Nháy đúp `BUILD_APK_WINDOWS.bat`. Script tự tải Flutter stable và Android command-line tools nếu thiếu, hỏi bạn chấp nhận Android SDK licenses (đọc và nhập `y` nếu đồng ý), tạo phần native, chạy phân tích và kiểm thử, rồi build APK. Khi build xong, script mở `output`.
4. Lấy `output\CAN_LUA_PRO_ANDROID.apk` và sao chép vào điện thoại Android; chạm file để cài đặt. Nếu Android báo chặn nguồn ngoài, vào phần cài đặt và cấp quyền cài ứng dụng cho **ứng dụng mở tệp đáng tin cậy**. Không cấp quyền rộng rãi cho nguồn không tin cậy.
5. Nhật ký lỗi nằm ở `output\build_YYYYMMDD_HHMMSS.log`. Đừng gửi log có đường dẫn hay thông tin cá nhân nhạy cảm nếu không cần thiết.

> Script không bỏ qua lỗi kiểm thử. Nếu thiếu kết nối mạng, thiếu phụ thuộc, không chấp nhận SDK licenses, hoặc Flutter API thay đổi làm mã nguồn lỗi, script sẽ dừng và **không** tạo APK giả.

## B. Không muốn cài Flutter trên PC – GitHub Actions

1. Mở thư mục giải nén và nháy đúp `PUSH_GITHUB_WINDOWS.bat` (cần Git for Windows và quyền ghi repo của bạn). Đăng nhập GitHub khi công cụ yêu cầu.
2. Mở https://github.com/ictmrthoai87-bit/phanmemcanlua/actions
3. Chọn **Build Android APK - Can Lua Pro**, chọn lần chạy thành công có dấu tích xanh.
4. Tải artifact **CAN_LUA_PRO_ANDROID_APK** xuống máy (GitHub tải về dưới dạng ZIP); giải nén lấy `CAN_LUA_PRO_ANDROID.apk`, gửi sang điện thoại Android để cài. Kiểm tra SHA256 nếu muốn.

Repository `phanmemcanlua` cần có mã nguồn Flutter và workflow `.github/workflows/flutter_ci.yml`. Nếu GitHub không cho phép Actions, bạn cần bật Actions trong cài đặt của repo. Nếu push thất bại do repo có commit khác, **không dùng git push --force**; cần xem xét thay đổi và merge trước.

## C. iPhone/iPad (iOS)

- Cần **máy Mac, Xcode, Flutter SDK, tài khoản Apple Developer và cấu hình Signing/Provisioning** nếu muốn IPA cài lên thiết bị ngoài chế độ phát triển.
- Trên Mac, mở Terminal tại thư mục và chạy `bash BUILD_IOS_MAC.command`. Script build và chép IPA vào `output` **khi** cấu hình ký số hợp lệ. Phương thức phát hành dùng TestFlight, App Store hoặc Apple Configurator/Ad Hoc theo tài khoản và thiết bị được Apple cho phép.
- Không có một IPA tự do cài vào mọi iPhone tương tự APK Android. Không thể build IPA phát hành hợp lệ trực tiếp trên Windows chỉ bằng cách đổi đuôi file.

## Phân biệt các mức phát hành

- **APK dùng thử:** release build theo template Flutter mặc định, có thể ký bằng khóa debug khi chưa cấu hình keystore phát hành. Cài trực tiếp trên Android, chưa phù hợp phân phối Google Play thương mại.
- **APK/AAB thương mại:** phải tạo keystore phát hành bảo mật, đặt applicationId cố định, cấu hình signing cho bản release, chính sách quyền riêng tư và thử nghiệm trên máy thực.
- **IPA/TestFlight:** phải có Apple signing hợp lệ.

Phiên bản V0.4 chỉ nhập số cân thủ công, không cần camera hoặc quyền ảnh để cân lúa.

## Windows BUILD hotfix V0.5.1

Xem `SUA_LOI_BUILD_FLUTTER_AGENTS.md` de sua loi PowerShell `Cannot find path ...\flutter\.agents`. SDK va project build tam su dung `%LOCALAPPDATA%\CLB`, khong giai nen Flutter trong duong dan `D:\soft\...` dai va co dau cach.
