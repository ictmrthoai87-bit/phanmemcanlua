**Chỉ có Windows?** Xem `docs/TAO_IPA_GITHUB_WINDOWS.md` để tạo IPA bằng GitHub Actions macOS 26.

# CÂN LÚA PRO 0.6.3 — TẠO FILE IPA THẬT CHO IPHONE/IPAD

**Tình trạng bộ này:** là mã nguồn và công cụ **tạo IPA**, không phải tệp IPA đã biên dịch.
Không thể build và ký IPA trên Windows hay Linux. Muốn IPA cài được trên iPhone cần máy Mac có Xcode,
Apple signing hợp lệ và thiết bị/ phương thức phân phối phù hợp.

## Tạo IPA bằng một lần chạy trên Mac

1. Cài Xcode từ App Store, Flutter SDK, CocoaPods nếu dự án dùng Podfile.
   Cấu hình Command Line Tools: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
2. Giải nén gói ZIP trên Mac, mở Terminal tại thư mục `CAN_LUA_PRO`.
3. Gõ: `bash TAO_IPA_TREN_MAC.command` (hoặc nhấp đúp trong Finder nếu macOS cho phép).
4. Khi được hỏi, nhập Bundle ID đã đăng ký với Apple (ví dụ `vn.tencongty.canluapro`).
   Chọn 4 để mở Xcode lần đầu, vào **Runner > Signing & Capabilities**:
   bật **Automatically manage signing** và chọn Apple Developer **Team**.
5. Chạy lại script, chọn một trong các kiểu phát hành:
   - **1 – App Store / TestFlight**: IPA để tải lên App Store Connect, không cài trực tiếp bằng Files.
   - **2 – Development**: cài thử trên thiết bị được provision cho phát triển.
   - **3 – Ad Hoc**: cài lên những iPhone/iPad có UDID trong profile.
6. Nếu build và ký thành công, script kiểm tra chữ ký và chép IPA vào `output/`.

Có thể chạy tự động nếu đã có Xcode Signing:

```bash
IOS_BUNDLE_ID=vn.tencongty.canluapro IOS_IPA_MODE=1 \
  bash scripts/create_signed_ipa_macos.sh
```

Dùng tùy chọn plist khi cần chọn profile xuất thủ công:

```bash
IOS_EXPORT_OPTIONS_PLIST="$HOME/ExportOptions.plist" IOS_IPA_MODE=1 \
  bash scripts/create_signed_ipa_macos.sh
```

**Không gửi** file `.p12`, mật khẩu Apple, provisioning profile hoặc API key bí mật vào trò chuyện.

## Dùng trên Windows nếu chưa có Mac

Bạn có thể lưu mã nguồn trong GitHub. Workflow `ios_device_build_check.yml` chạy trên máy Mac của GitHub,
chỉ xác nhận iOS release **unsigned** biên dịch thành công. Nó **không** tạo IPA đã ký.
Để có IPA dùng được trên iPhone phải bổ sung quyền ký của Apple vào Mac/runner một cách bảo mật.

## Giữ nguyên tính năng

Nhập cân thủ công, lưu lượt cân ở sát ô nhập, cấu hình giá/số lẻ/bì riêng,
trừ bì theo bao hoặc trừ cuối, quy đổi bao, CSV, sao lưu, dữ liệu SQLite,
phiên bản 0.6.3, dòng Edit: Lê Ngọc Thoại. Không có OCR/AI/camera.

## Lưu ý kỹ thuật

- Bộ gốc V0.6.3 được dùng làm nguồn; thư mục `ios/` được Flutter tạo lần đầu trên macOS.
- `flutter build ipa` có thể yêu cầu certificate/provisioning và Apple Developer membership.
- Trên Mac, các phiên bản Xcode/Flutter phải tương thích; nếu lỗi kiểm tra log `output/ipa_build_*.log`.
- Build IPA qua App Store cần khai báo privacy/metadata/chính sách bảo mật nếu phát hành thương mại.
- Chưa chạy build IPA thực tế trong môi trường tạo gói này; chỉ kiểm tra cú pháp shell và Python.

Tài liệu chính thức: https://docs.flutter.dev/deployment/ios
