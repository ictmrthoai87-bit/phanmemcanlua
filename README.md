# CHAY BUILD IPA TREN MAC CLOUD BANG WINDOWS

**Dành cho người chỉ có Windows:** xem [`docs/TAO_IPA_GITHUB_WINDOWS.md`](docs/TAO_IPA_GITHUB_WINDOWS.md). Chạy GitHub Actions workflow `CAN LUA PRO V0.6.3 - IPA tren Mac Cloud` để kiểm tra iOS hoặc xuất IPA đã ký.

Bắt đầu bằng `README_IOS_CLOUD_WINDOWS.txt`. File IPA thực tế chỉ xuất hiện trong GitHub Actions sau khi cung cấp chứng chỉ Apple phù hợp và build thành công. Đừng đưa file ký vào mã nguồn.

---

# CÂN LÚA PRO V0.6.3 — Android & iOS

**Phiên bản:** 0.6.3 (build 19)  
**Dòng hiển thị trong ứng dụng:** Edit: Lê Ngọc Thoại  
**Nơi hiển thị:** dưới tên ứng dụng trên thanh trên cùng; phần Giới thiệu ở cuối tab CẤU HÌNH.

Phiên bản V0.6.3 chỉ cập nhật phần thông tin tên người biên tập và phiên bản, giữ nguyên chức năng V0.6.2 và dữ liệu cân đã lưu. Không có AI/OCR.

**Thay đổi trong tương lai:** đồng bộ `pubspec.yaml` và `lib/core/app_info.dart` khi tăng phiên bản. `pubspec.yaml` quản lý version/build cho tệp cài đặt Android và iOS; các hằng trong `app_info.dart` là thông tin hiển thị trong giao diện.

---

# CÂN LÚA PRO 0.6.0 — Android & iOS

**Ứng dụng cân lúa cho nông dân và cơ sở thu mua.** Dùng Flutter, SQLite, nhập
số cân thủ công, trừ bì theo bao hoặc trừ cuối, tính tiền, quản lý lô và
sao lưu/chia sẻ. **Không có AI/OCR/QR và không cần camera.**

## iPhone / iPad
Trên máy Mac có Flutter, Xcode và CocoaPods:
```bash
cd CAN_LUA_PRO
bash BUILD_IOS_MAC.command
```
Chọn mở Xcode để cài thử lên iPhone, build Simulator hoặc xuất IPA ký số.
Hướng dẫn từng bước: `docs/HUONG_DAN_IOS_V060.md`.

## Android
Trên Windows, chạy `BUILD_APK_WINDOWS.bat` (script có trong bộ mã nguồn).
Mã nguồn Android dùng chung thư mục `lib/` với iOS.

## Chính sách lưu trữ
Dữ liệu lưu cục bộ trong SQLite. Mỗi thiết bị lưu riêng. Trước khi gỡ ứng dụng
hoặc thay thiết bị, cần xuất sao lưu JSON vì thao tác đó có thể làm mất dữ liệu.

## Trạng thái kiểm thử
Bộ ZIP và các tập tin tạo iOS đã qua kiểm tra cấu trúc và cú pháp Python/Bash.
**Chưa thể build, ký IPA hay thử trực tiếp trên iPhone** trong môi trường Linux
không có Xcode. TestFlight / App Store chỉ thực hiện sau khi đã cấu hình
chứng chỉ Apple và thử nghiệm trên thiết bị thật.

---

## MỚI trong V0.6.1: dấu ✓ lưu ngay lượt cân và báo cáo bao quy đổi

- **Nhập kg → nhấn ✓/Done trên bàn phím** sẽ gọi trực tiếp hàm lưu một lượt (không cần nhấn tiếp nút lưu), có cảnh báo nếu nhập trùng trong 90 giây.
- Mục **BÁO CÁO** hiển thị toàn bộ lượt, tổng kg, tổng bì, kg thực và số bao quy đổi từng lượt/toàn lô.
- **Kg trên mỗi bao quy đổi có thể cấu hình riêng theo lô, mặc định 50 kg** và không lẫn với số bao thực nhập để tính bì.
- Trừ bì **theo đầu bao** hoặc **trừ cuối**, không cộng trừ hai lần; nếu trừ cuối chưa nhập bì, báo cáo cảnh báo tạm tính.
- Báo cáo CSV, phiếu cân được mở rộng; dữ liệu SQLite tự nâng cấp v1-v3 lên v4, không xóa lịch sử.
- Một gói source Flutter cho cả Android và iOS. Xem [`THIET_KE_TONG_HOP_ANDROID_IOS_V061.md`](THIET_KE_TONG_HOP_ANDROID_IOS_V061.md).

**Cài đặt chưa được build/kiểm thử trên thiết bị thực tế trong môi trường đóng gói.**


## V0.6.2 — Giao diện cân nhanh tối giản (Android/iOS)

- Chỉ còn **một nút LƯU LƯỢT CÂN** lớn, ngay dưới ô nhập kg, số bao và ghi chú ngắn.
- Đã bỏ dấu lưu riêng trong ô kg; phím Done của bàn phím đóng bàn phím, **không tự thêm một lượt cân**.
- Trang CÂN NHANH chỉ hiển thị thông tin lô, tổng kết, các ô dữ liệu của lượt cân và lịch sử.
- Tab **CẤU HÌNH** chứa đơn giá/đã thanh toán, lựa chọn 1 hay 2 số lẻ, cách trừ bì/nhập bì trừ cuối và kg/bao quy đổi. Cài đặt lưu theo từng lô, lịch sử giữ nguyên.
- Trong chế độ trừ bì đầu bao, **số bao của mỗi lượt** vẫn phải nhập tại CÂN NHANH. Đó là dữ liệu lượt cân, không phải thiết lập chung.
- Các chức năng chia sẻ, sao lưu/khôi phục và nhật ký vẫn nằm phía dưới tab CẤU HÌNH.
- Flutter Analyze/Test và build APK/IPA cần được chạy trong môi trường có SDK; kiểm tra Python không thay thế kiểm thử ứng dụng trên điện thoại thật.

**Bố cục V0.6.2:** khối nhập/lưu cân nằm ngay dưới tên lô; tổng kg và tiền ngay sau đó. Ghi chú thu gọn, chỉ hiện khi người dùng yêu cầu.
