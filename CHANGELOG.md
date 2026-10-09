## V0.6.3 — 2026-10-10
- Hiển thị "Edit: Lê Ngọc Thoại" và phiên bản V0.6.3 dưới tên ứng dụng.
- Thêm mục "GIỚI THIỆU PHẦN MỀM" ở tab CẤU HÌNH, có tên phiên bản và biên tập.
- Tập trung thông tin trong lib/core/app_info.dart để thay đổi phiên bản sau này.
- Đồng bộ pubspec.yaml: 0.6.3+19 (Android versionName/versionCode; iOS short version/build).
- Không thay đổi chức năng lưu cân, trừ bì, đơn giá, quy đổi bao hoặc SQLite.
- Không thêm AI, OCR, camera.

## V0.6.2 — 2026-10-10
- Tối giản thao tác nhập cân; một nút LƯU LƯỢT CÂN sát ô nhập.
- Bỏ icon lưu trong ô số cân; phím Done không lưu lượt cân.
- Gom đơn giá, số lẻ, cách trừ bì, bao quy đổi vào tab CẤU HÌNH.
- Bỏ các nút cài đặt rải rác trong CÂN NHANH/BÁO CÁO.
- Giữ nguyên schema SQLite v4, không làm mất lượt cân đã lưu.
- Không bổ sung AI/OCR/camera.

# CAN LUA PRO 0.6.0 — iOS / iPad

- Them script build iOS Mac co che do prepare, check, simulator, install, ipa.
- Them icon chu de bong lua cho iPhone/iPad.
- Cau hinh ten Cân Lúa Pro, vi/en, target 15.5, Bundle ID tuy chon.
- Them anchor share_plus cho iPad, giu nguyen hai che do tru bi va SQLite.
- Khong them camera/AI/OCR.
- Xem docs/HUONG_DAN_IOS_V060.md.

## V0.6.1 — Lưu bằng nút ✓ của bàn phím, báo cáo kg/bao theo lượt

- `TextInputAction.done` + `onSubmitted` gọi `_addManual`, có chống lặp khi đang lưu.
- Màn hình BÁO CÁO mới: từng lượt, kg thực, bao tương đương, tổng kg, CSV.
- Mỗi lô cấu hình trọng lượng 1 bao quy đổi (mặc định 50 kg; không phải bao để tính bì).
- SQLite schema v4 và backup v3; giữ đọc backup v1/v2; báo cáo bao trừ cuối mang nhãn tạm tính.
- Thêm kiểm thử tính bao theo gram, quy đổi/tổng cân, xuất CSV; không có AI/camera.

### iOS CLOUD KIT (build infrastructure, retains app version V0.6.3)
- GitHub Actions manual cloud build on macOS 26 with Xcode.
- Modes: unsigned_check, signed_ipa, signed_ipa_testflight.
- Secure ephemeral keychain, signed IPA verification, GitHub artifact delivery.
- Windows CSR/P12/Base64 helper for Apple Developer portal.
- Private signing files excluded from Git; no secrets embedded in source.
