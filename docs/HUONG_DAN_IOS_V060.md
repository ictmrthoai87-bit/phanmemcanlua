# CÂN LÚA PRO 0.6.0 — chạy trên iPhone và iPad

**Bộ này là mã nguồn Flutter hoàn chỉnh kèm công cụ tạo dự án Xcode. Không chứa IPA ký sẵn.**

## Phần mềm làm được gì?
Nhập cân thủ công, trừ bì theo số bao hoặc trừ tổng ở cuối lô, một/hai số lẻ,
giá tiền đồng/kg, tổng tiền, đã trả, còn nợ, sổ cân nhiều khách hàng/lô,
phiếu cân chia sẻ qua ứng dụng có sẵn trên điện thoại, xuất CSV và sao lưu JSON.
Không có AI/OCR, không yêu cầu camera. Dữ liệu SQLite lưu ngay trên từng thiết bị,
không tự đồng bộ giữa các máy.

## Cài để dùng thử trên iPhone (không phải IPA phát hành)
1. Trên **máy Mac**, cài Xcode từ App Store và mở một lần, cài Flutter và CocoaPods.
   Làm theo https://docs.flutter.dev/platform-integration/ios/setup
2. Giải nén tệp ZIP này vào thư mục đơn giản, ví dụ `~/Projects/CAN_LUA_PRO`.
3. Trong Terminal mở thư mục `CAN_LUA_PRO`, chạy:

   ```bash
   chmod +x BUILD_IOS_MAC.command scripts/build_ios_macos.sh
   bash scripts/build_ios_macos.sh --install
   ```

   Lệnh này tạo `ios/Runner.xcodeproj` nếu chưa có và mở `ios/Runner.xcworkspace`.
4. Xcode > Runner > Signing & Capabilities: bật **Automatically manage signing**;
   chọn Team (Apple ID), đặt **Bundle Identifier duy nhất**. Apple ID cá nhân có
   thể dùng cài thử trên thiết bị đủ điều kiện; TestFlight/App Store cần Apple Developer Program.
5. Kết nối iPhone với Mac, chọn Trust this Computer, bật Developer Mode nếu Xcode yêu cầu;
   chọn thiết bị thật trong Xcode và nhấn Run. Dữ liệu ứng dụng lưu trên iPhone đó.

## Build iOS Simulator, dùng khi chưa có iPhone
```bash
bash scripts/build_ios_macos.sh --simulator
```
Kết quả ở `output/CAN_LUA_PRO_iOS_SIMULATOR_ONLY.zip` **không cài được trên iPhone thật**.

## Tạo IPA để TestFlight/App Store
1. Đăng ký Apple Developer Program, cấu hình Bundle ID và Signing & Capabilities.
2. Chạy `bash scripts/build_ios_macos.sh --ipa` trên Mac đã cấu hình ký số.
3. IPA sẽ được sao chép vào `output/` khi build và ký thành công.
4. Upload bằng Apple Transporter hoặc Xcode Organizer lên App Store Connect;
   sau đó phát hành thử trên TestFlight.

**Không có cách tạo IPA ký và cài lên iPhone bất kỳ chỉ bằng Windows/Android APK.**
Nếu chỉ có Windows, bạn có thể chạy CI `ios_ci.yml` qua GitHub Actions macOS
để kiểm tra Simulator; việc phát hành bản IPA vẫn cần tài khoản Apple,
thông tin ký số và cấu hình phân phối.

## Cấu hình app và tương thích
- Flutter source v0.6.0; iOS deployment target 15.5, tương thích iOS 15.5 trở lên.
- Nhãn ứng dụng: **Cân Lúa Pro**, localizations `vi`, `en`.
- Có bộ App Icon iPhone/iPad trong `ios_assets/AppIcon.appiconset/`.
- `scripts/configure_ios_native.py` tự chép icon và thiết lập Info.plist/pbxproj trên Mac.
- Tùy chọn Bundle ID qua `export IOS_BUNDLE_ID=vn.congty.canluapro` (không ghi cứng chứng chỉ).
- Share sheet có vị trí mở riêng cho iPad tránh lỗi popover.
- Không dùng camera, OCR hoặc quét QR.
- Sao lưu JSON chứa dữ liệu giao dịch, không gửi cho người lạ.
- Khi gỡ ứng dụng hoặc đổi máy, cần xuất sao lưu rồi khôi phục trên máy mới.

## Kiểm tra trước khi phát hành thương mại
Kiểm thử trên iPhone/iPad thật, quyền xem/tạo file, Zalo share sheet, khôi phục JSON,
decimal/thực nhận/trừ bì hai chế độ, thay đổi lô và bảo toàn SQLite khi nâng cấp.
Cần hồ sơ App Store, privacy policy và rà soát yêu cầu `PrivacyInfo.xcprivacy`
theo plugin và thư viện thực tế. Không cam kết đã được Apple duyệt hay ký số.

## Trợ giúp lỗi
Log ở `output/ios_YYYYMMDD_HHMMSS.log`. Nếu `pod install` lỗi, kiểm tra Xcode,
CocoaPods và iOS minimum deployment target. Nếu lỗi signing, mở Xcode,
chọn Team và Bundle ID hợp lệ rồi chạy lại.
