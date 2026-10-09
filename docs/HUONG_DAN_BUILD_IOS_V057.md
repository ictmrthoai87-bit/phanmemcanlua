# CÂN LÚA PRO V0.5.7 – Hướng dẫn cài thử và phát hành iPhone/iPad

## 1. Điều kiện

Cùng mã nguồn Flutter với Android V0.5.6: nhập cân bằng tay, tính tổng, 2 chế độ trừ bì, đơn giá, sổ cân, phiếu cân, JSON/CSV. Không AI/Camera. **Không cài file APK lên iPhone.**

Cần **Mac có Xcode và Flutter SDK bản macOS**. Java/Flutter và Android SDK cài trên Windows trước đây không thay thế công cụ iOS trên Mac. Cần cài CocoaPods (`brew install cocoapods` nếu có Homebrew). Kiểm tra bằng `flutter doctor -v`.

## 2. Cài thử trên iPhone bằng tài khoản Apple ID (không bắt buộc mua gói Developer chỉ để thử thiết bị)

1. Chép **nguyên thư mục `CAN_LUA_PRO`** từ ZIP sang máy Mac rồi giải nén. Đảm bảo lưu thư mục ở nơi có quyền ghi, ví dụ `~/Documents/CAN_LUA_PRO`.
2. Cài Xcode từ Mac App Store và Flutter SDK bản Mac theo tài liệu Flutter. Mở Xcode và hoàn thành cài đặt các thành phần.
3. Trong Terminal mở thư mục phần mềm, chạy `chmod +x BUILD_IOS_MAC.command` một lần nếu cần, sau đó chạy `./BUILD_IOS_MAC.command` hoặc nhấp đúp vào script trên Finder.
4. Chọn **1 – Mở Xcode**. Script tự tạo phần iOS (chỉ nếu chưa có), cấu hình tên app và gỡ quyền camera không dùng, cài dependencies, chạy phân tích/test, rồi mở `ios/Runner.xcworkspace`.
5. Xcode: chọn `Runner` > `Signing & Capabilities` > `Automatically manage signing` và `Team` gắn với Apple ID. Đặt **Bundle Identifier duy nhất** trong `Runner` > `General`/`Signing & Capabilities` (ví dụ `vn.tencongty.canluapro`). **Giữ nguyên Bundle ID cho các bản cập nhật**.
6. Cắm iPhone bằng cáp, mở khóa và chọn **Trust** khi được hỏi. Nếu yêu cầu, vào `Cài đặt > Quyền riêng tư & Bảo mật > Chế độ nhà phát triển` để bật Developer Mode.
7. Trong Xcode chọn thiết bị iPhone và nhấn **Run (▶)**. Xcode ký và cài thử app lên thiết bị; cấp phép tin cậy chứng chỉ nếu iPhone yêu cầu.

Dùng Apple ID miễn phí có thể thử cài lên iPhone của chính mình, nhưng có giới hạn về cấp phép/thời hạn ứng dụng. Để phát hành cho nhiều người sử dụng, dùng tài khoản Apple Developer Program.

## 3. Test nhanh trên iOS Simulator

Trên Mac, chạy `./BUILD_IOS_MAC.command`, chọn **2**. Kết quả build cho simulator nằm ở `build/ios/iphonesimulator/Runner.app`. **Đây không phải file IPA cài trên iPhone.** Có thể khởi động Simulator trong Xcode để thử giao diện. Kiểm tra trên máy thật vẫn cần thiết (thao tác nhập liệu và chia sẻ tệp).

## 4. Tạo IPA để phát hành TestFlight hoặc App Store

1. Đăng ký chương trình Apple Developer Program; tạo Bundle ID và app trên App Store Connect.
2. Mở `ios/Runner.xcworkspace`, chọn đúng Team và bật tự động ký. Cần hồ sơ ký/phân phối phù hợp.
3. Chạy `./BUILD_IOS_MAC.command`, chọn **3 – IPA release**; khi ký thành công, file `.ipa` được chép vào `CAN_LUA_PRO/output/`.
4. Dùng **Xcode Organizer** hoặc **Transporter** để tải IPA lên **App Store Connect**. Chọn **TestFlight** cho nhóm dùng thử, sau khi thử nghiệm đầy đủ mới gửi xét duyệt App Store.
5. Chuẩn bị tên/biểu tượng thương mại, ảnh chụp màn hình, chính sách quyền riêng tư, thông tin hỗ trợ, kịch bản kiểm thử dữ liệu cân và giá tiền. Không sử dụng cấu hình debug hoặc chứng chỉ thử nghiệm làm bản phát hành.

App Store Connect yêu cầu phiên bản Xcode phù hợp tại thời điểm upload; theo tài liệu Apple, **ứng dụng iOS phát hành tại thời điểm 2026 yêu cầu build bằng Xcode 26 trở lên** (quy tắc có thể thay đổi).

## 5. Không có Mac thì sao?

- Có thể tiếp tục phát triển Dart/Flutter bằng Windows nhưng **không tạo IPA iPhone trực tiếp trên Windows**.
- Có thể thuê Mac, dùng Mac của đối tác hoặc dịch vụ build macOS hỗ trợ ký Apple. Kết quả không thể cài lên iPhone nếu chưa được ký hợp lệ.
- Có workflow `ios_ci.yml` trong ZIP để **kiểm tra build iOS Simulator** trên runner macOS của GitHub Actions (sau khi bạn đẩy mã nguồn lên GitHub). Artifact chỉ dành cho **Simulator**, **không phải IPA đã ký để cài iPhone**.

## 6. Sao lưu và bảo vệ dữ liệu nông dân

- Sao lưu JSON trước khi đổi Bundle ID/gỡ ứng dụng; bản sao lưu JSON chưa mã hóa, không đăng công khai.
- Dữ liệu cân lưu SQLite trong máy, không tự đồng bộ giữa iPhone và Android; hiện tại phải dùng tính năng sao lưu/khôi phục nếu muốn chuyển dữ liệu.
- Không thay Bundle ID/Tên gói một cách tùy tiện ở các bản nâng cấp nếu cần giữ lại dữ liệu của app trước đó.

## Tài liệu chính thức

- Flutter iOS setup: https://docs.flutter.dev/platform-integration/ios/setup
- Flutter iOS distribution: https://docs.flutter.dev/deployment/ios
- Apple TestFlight: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Apple Xcode signing: https://help.apple.com/xcode/mac/current/en.lproj/dev5a825a1ca.html

**Trạng thái:** Mã nguồn, cấu hình và script đã kiểm tra tĩnh trên Linux. Chưa chạy Xcode/Flutter trên Mac, chưa có IPA đã ký, chưa kiểm thử iPhone thật. Kết quả build phụ thuộc SDK, phiên bản plugin và chứng chỉ Apple của máy thực hiện.
