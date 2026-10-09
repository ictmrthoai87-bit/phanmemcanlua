# CÂN LÚA PRO V0.6.3 – TẠO IPA CHO iPHONE TỪ WINDOWS BẰNG MAC CLOUD

**Phiên bản ứng dụng:** 0.6.3+19  
**Thông tin hiển thị:** Edit: Lê Ngọc Thoại  
**Chức năng:** nhập cân thủ công, lưu lượt cân, trừ bì theo bao / cuối, báo cáo, kg/bao, không dùng camera/AI.

## I. Phân biệt 3 kết quả

| Chế độ trong GitHub Actions | Có cần Apple Developer? | Kết quả |
|---|---|---|
| `unsigned_check` | Không | Xây dựng app iOS để phát hiện lỗi Flutter/Xcode; KHÔNG tạo IPA dùng cài máy thật |
| `signed_ipa` | Có, đang hoạt động | Xuất IPA App Store Connect ký hợp lệ, tải từ Actions Artifacts |
| `signed_ipa_testflight` | Có + API key | Tạo IPA ký và thử tải lên App Store Connect, sau khi Apple xử lý có thể mời cài qua TestFlight |

**Lưu ý:** IPA xuất theo App Store Connect KHÔNG phải file có thể tự bấm trên iPhone để cài. Để cài cho nhiều người, dùng **TestFlight** hoặc App Store. Nếu cần cài ngoài TestFlight lên các iPhone cụ thể, phải làm cấu hình Ad Hoc theo danh sách UDID và hồ sơ cấp phép riêng (chưa bao gồm trong workflow này).

## II. Chuẩn bị một lần trên Windows

1. Có tài khoản GitHub, mạng Internet; cài **Git for Windows**.
2. Tài khoản **Apple Developer Program có trả phí, còn hiệu lực**, được quyền tạo **Certificates, Identifiers & Profiles**. Để tải lên TestFlight, cần App Store Connect và quyền liên quan.
3. Tạo repository **PRIVATE**, ví dụ `phanmemcanlua`. Mã nguồn trước đó của bạn có thể đang ở kho public; cân nhắc đổi thành private trước khi cấu hình secrets hoặc đưa ứng dụng thương mại lên đó.
4. Tải/giải nén gói này vào thư mục dễ nhớ, ví dụ `D:\CAN_LUA_PRO\CAN_LUA_PRO`. Mở `PUSH_GITHUB_WINDOWS.bat` để đẩy lên repo. Nếu lần đẩy báo lỗi do repo đã có commit, **không dùng `git push --force`**; sao lưu và hợp nhất với nhánh hiện có trước.
5. Đăng nhập GitHub trên máy Windows; vào **repository → Actions → CAN LUA PRO V0.6.3 - IPA tren Mac Cloud → Run workflow**. Lần đầu hãy chọn `unsigned_check` để kiểm tra mã nguồn và khả năng build trên Mac mà **chưa cần chứng chỉ Apple**.

### Ghi chú bảo mật

Đừng tải bất kỳ file `.p12`, `.p8`, `.key`, `.mobileprovision`, mật khẩu hoặc nội dung Base64 lên chat, issue GitHub hay commit. Chỉ nhập qua **GitHub → Settings → Secrets and variables → Actions → New repository secret**. File ZIP này **không chứa** khóa ký, hồ sơ Apple hoặc mật khẩu.

## III. Tạo Apple Distribution certificate khi CHỈ CÓ Windows

1. Chạy `APPLE_CHUNG_CHI_WINDOWS.bat`, chọn **1**. Script dùng OpenSSL từ Git for Windows để tạo:
   - `APPLE_SECRET_LOCAL_ONLY/canlua_apple_distribution_PRIVATE.key` – khóa riêng (giữ kín và sao lưu).
   - `APPLE_SECRET_LOCAL_ONLY/canlua_apple_distribution.csr` – yêu cầu cấp chứng chỉ (được gửi Apple).
2. Truy cập [Apple Developer – Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list), tạo **Apple Distribution** certificate, tải CSR ở bước trên lên rồi tải về chứng chỉ `.cer`.
3. Chạy `APPLE_CHUNG_CHI_WINDOWS.bat` chọn **2** và cung cấp file `.cer`. Đặt mật khẩu mạnh cho `.p12` (ít nhất 12 ký tự). Script tạo `CanLuaPro_AppleDistribution.p12` có **chứng chỉ + private key**.
4. Trong Apple Developer tạo **App ID** (Explicit) với Bundle ID duy nhất, ví dụ `vn.canlua.canluapro`. Bundle ID phải trùng trong App Store Connect, provisioning profile và GitHub Secret `IOS_BUNDLE_ID`.
5. Tạo **App Store Connect distribution provisioning profile** (không phải Development, Ad Hoc) cho App ID đó, dùng Apple Distribution certificate vừa tạo, rồi tải file `.mobileprovision` về Windows.
6. Chạy `APPLE_CHUNG_CHI_WINDOWS.bat`, chọn **3** rồi chọn file `.mobileprovision`. Script ghi 2 file văn bản Base64 trong thư mục `APPLE_SECRET_LOCAL_ONLY`.

Apple có thể giới hạn việc tạo thêm chứng chỉ cho tài khoản; nếu bạn đã có chứng chỉ Distribution phù hợp **kèm private key**, có thể xuất `.p12` từ nơi lưu trữ hợp lệ thay vì tạo một cái mới.

## IV. Tạo GitHub Secrets (chính xác tên)

Vào **repository → Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Giá trị |
|---|---|
| `IOS_BUNDLE_ID` | Bundle ID đã đăng ký, ví dụ `vn.canlua.canluapro` |
| `APPLE_TEAM_ID` | Apple Team ID 10 ký tự, tìm trong Membership |
| `BUILD_CERTIFICATE_BASE64` | Toàn bộ nội dung `APPLE_SECRET_LOCAL_ONLY/BUILD_CERTIFICATE_BASE64.txt` |
| `P12_PASSWORD` | Mật khẩu đã đặt khi tạo P12 |
| `BUILD_PROVISION_PROFILE_BASE64` | Toàn bộ nội dung `APPLE_SECRET_LOCAL_ONLY/BUILD_PROVISION_PROFILE_BASE64.txt` |

Chỉ khi muốn **tự động upload lên TestFlight** thì thêm:

| Secret | Giá trị |
|---|---|
| `APPLE_API_KEY_ID` | Key ID của App Store Connect API Key |
| `APPLE_API_ISSUER_ID` | Issuer ID tương ứng với API Key |
| `APPLE_API_PRIVATE_KEY_BASE64` | Nội dung `.p8` mã hóa Base64; tạo bằng `APPLE_CHUNG_CHI_WINDOWS.bat` lựa chọn **4** |

Tạo API Key ở **App Store Connect → Users and Access → Integrations → App Store Connect API**. Dùng quyền cần thiết, chỉ tạo Team Key khi phù hợp chính sách tài khoản. App Store Connect API Key không thay thế chứng chỉ và provisioning profile ký iOS.

## V. Bấm nút để tạo IPA trên Mac Cloud

1. GitHub → **Actions** → **CAN LUA PRO V0.6.3 - IPA tren Mac Cloud** → **Run workflow**.
2. Chọn `signed_ipa` (hoặc `signed_ipa_testflight` nếu đã có thêm 3 secret API Key).
3. Đợi workflow chạy trên GitHub-hosted **macos-26** (Xcode, Flutter, CocoaPods, kiểm thử và code signing). GitHub có thể tính phí/phút nếu vượt hạn mức Actions.
4. Nếu thành công: mở **workflow run → Artifacts → CAN_LUA_PRO_V0.6.3_IOS_SIGNED_IPA** để tải ZIP artifact. Giải nén ZIP artifact để lấy `.ipa`.
5. Ở chế độ TestFlight, chờ Apple xử lý build; vào App Store Connect → TestFlight để thêm nhóm và người thử nghiệm. Nếu Apple yêu cầu thông tin mã hóa, quyền riêng tư, độ tuổi hoặc xét duyệt beta, hãy hoàn thành các mục đó trên App Store Connect.

## VI. Nếu workflow báo đỏ

Mở workflow run → `ios-cloud` → bước bị lỗi → Copy log hoặc tải run logs. **Chỉ chia sẻ đoạn log KHÔNG chứa secrets**, không gửi `.p12`, `.key`, `.p8`, `.mobileprovision`.

- `flutter analyze` / `flutter test`: lỗi mã nguồn.
- `flutter build ios --no-codesign`: lỗi Flutter, plugin, CocoaPods, Xcode; chưa liên quan Apple Signing.
- `THIEU GitHub Secrets`: sai tên/thiếu cấu hình secrets.
- `provisioning profile khong khop`: sai Team ID, Bundle ID hoặc chọn nhầm profile Ad Hoc/Development.
- `Apple Distribution identity not found`: P12 không chứa private key hoặc mật khẩu sai.
- `No such module`, `pod install`: kiểm tra cấu hình CocoaPods / plugin.
- `xcodebuild archive/exportArchive`: xem phần CODE SIGN, profile, entitlement hoặc yêu cầu Xcode hiện hành.
- `altool upload`: kiểm tra API Key, quyền App Store Connect và tình trạng hồ sơ ứng dụng.

## VII. Giới hạn đã xác minh

Các script được kiểm tra tĩnh trên Linux; **chưa chạy Xcode và chưa có IPA ký số** tại thời điểm tạo gói. Không thể đảm bảo build cloud không có lỗi mới trước khi GitHub Actions thực sự chạy.

Nguồn tham khảo chính thức:
- https://docs.flutter.dev/deployment/ios
- https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
