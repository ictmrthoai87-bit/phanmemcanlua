# CÂN LÚA PRO V0.6.2 — HƯỚNG DẪN GIAO DIỆN MỚI

## 1. CÂN NHANH
1. Chọn lô cân cần sử dụng.
2. Nhập khối lượng cân (kg) bằng bàn phím số.
3. Nếu phương pháp trừ bì theo đầu bao, nhập **số bao thực tế của lượt này**; khi trừ cuối, mục số bao không hiện.
4. Nếu cần ghi chú, chọn **Thêm ghi chú** rồi nhập.
5. Nhấn nút xanh **LƯU LƯỢT CÂN** ngay bên dưới để lưu. Không còn nút ✓ thứ hai bên trong ô kg. Phím Done trên bàn phím chỉ đóng bàn phím.
6. Sau khi lưu, ô kg được xóa để nhập lượt tiếp. Tổng khối lượng, bao quy đổi và tiền tự cập nhật bên dưới.

**Lưu ý:** Không nhấn LƯU hai lần cho cùng một lượt. Nếu trùng kg/bì trong vòng 90 giây, phần mềm yêu cầu xác nhận. Có thể sửa hoặc xóa lượt cân bằng menu bên cạnh lượt cân.

## 2. CẤU HÌNH
Mở tab **CẤU HÌNH** dưới màn hình hoặc biểu tượng bánh răng phía trên:
- **Đơn giá và thanh toán:** nhập giá đồng/kg, bấm LƯU GIÁ; cập nhật số tiền đã trả riêng.
- **Số lẻ:** chọn một hoặc hai chữ số sau dấu phẩy. Nếu lịch sử có cân 2 số lẻ, phần mềm không cho giảm về 1 số lẻ.
- **Trừ bì:** lựa chọn theo đầu bao hoặc trừ cuối. Khi đã lưu lượt cân, không đổi phương pháp trong lô cũ nhằm tránh tính sai. Với trừ cuối, nhập tổng bì cuối trong CẤU HÌNH, bấm LƯU BÌ.
- **Quy đổi bao:** cài số kg tương đương một bao, mặc định 50 kg. Đây không phải số bao vật lý để tính bì.
- Phía dưới vẫn có **chia sẻ phiếu cân, xuất CSV, sao lưu/khôi phục**.

## 3. BÁO CÁO VÀ SỔ CÂN
- Báo cáo liệt kê lượt cân, tổng cân, tổng bì, kg thực, số bao quy đổi, tiền.
- Sổ cân quản lý từng lô/khách hàng. Những lô V0.6.1 vẫn dùng database SQLite schema v4, không có di chuyển dữ liệu.

## 4. CÀI ĐẶT
- Android: giải nén và chạy BUILD_APK_WINDOWS.bat trên Windows đã chuẩn bị Java, Flutter, Android SDK/NDK. APK chỉ xuất hiện khi build hoàn thành.
- iOS: chạy BUILD_IOS_MAC.command trên macOS có Flutter và Xcode, cấu hình ký ứng dụng trước khi cài iPhone hoặc xuất IPA.

**Kiểm thử:** kiểm tra tĩnh/UI và SQLite có thể chạy `python scripts/verify_ui_v062.py`, `python scripts/static_verify.py`, `python scripts/prebuild_verify.py`. Kiểm tra này không thay thế `flutter analyze`, `flutter test`, `flutter build apk` hay build iOS trên macOS.
