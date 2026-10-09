# LỘ TRÌNH THƯƠNG MẠI CÂN LÚA PRO — CẬP NHẬT V0.5

## Đã có trong V0.5 (mã nguồn)

- Giao diện nút lớn, màn hình Cân nhanh / Sổ cân / Tiện ích rõ ràng.
- **Nhập tay 100%** bằng bàn phím; không AI, OCR, camera, QR/mã vạch.
- Bì theo đầu bao (bì/bao × số bao của lượt) hoặc tổng bì trừ một lần cuối; 1 hoặc 2 số lẻ; tổng cân, đơn giá, thành tiền.
- Sổ lô, khách hàng, giống lúa, lịch sử/sửa/xóa, cảnh báo trùng số cân trong thời gian gần.
- Theo dõi tiền đã trả/còn lại, chia sẻ phiếu, xuất CSV, sao lưu/khôi phục JSON; dùng SQLite offline.

## Trước khi bán thử

1. Biên dịch APK trên máy có Flutter/Android SDK, chạy `flutter analyze`, `flutter test`; kiểm thử trên máy Android thực.
2. Kiểm thử nâng cấp trên cùng applicationId và cùng khóa ký từ V0.3/V0.4; đảm bảo các lượt cân cũ, kể cả nguồn gốc OCR cũ, vẫn nguyên vẹn.
3. Kiểm thử thực địa với bà con: bàn phím số, đơn vị kg, 1/2 chữ số lẻ, trừ bì theo đầu bao/trừ bì sau, nhận diện số đã nhập trùng.
4. Kiểm thử không mạng, tắt nguồn khi nhập, bộ nhớ đầy, ghi dữ liệu liên tiếp; kiểm soát bấm Lưu nhiều lần.
5. Chính sách bảo vệ dữ liệu cá nhân, lưu trữ và phục hồi; mã hóa sao lưu nếu có thông tin khách hàng.
6. Cấu hình Android keystore/app ID ổn định, Apple Developer signing, biểu tượng ứng dụng, điều khoản sử dụng.

## Các hướng phát triển tiếp theo không sử dụng AI

- In phiếu cân qua máy in nhiệt Bluetooth 58/80 mm và phiếu PDF.
- Danh bạ khách, công nợ theo nhiều lần thanh toán, mùa vụ, tên giống lúa, báo cáo theo ngày/tháng.
- Cho phép cấu hình quy tắc giảm trừ theo hợp đồng (độ ẩm/tạp chất) minh bạch, không gắn công thức mặc định cho mọi giao dịch.
- Tài khoản nhân viên, đồng bộ có kiểm soát, mã hóa thông tin, backup đám mây, gói thuê bao thương mại.

## Tiêu chí nghiệm thu

- Kiểm thử đầy đủ phép tính khối lượng, tiền và trừ bì trong các tình huống giới hạn.
- Không mất dữ liệu khi nâng cấp trên thiết bị thật và khi khôi phục backup.
- Quyền camera/ảnh không tồn tại trong ứng dụng phân phối nếu không có tính năng khác cần dùng.
- Nhập cân, trừ bì, lưu lượt và in/gửi phiếu thuận tiện khi đứng ngoài đồng.
- Từng lượt cân lưu từ ứng dụng mới có nguồn `Nhập tay`.

**V0.5 vẫn là bản thử nghiệm, chưa được chứng nhận hoặc phát hành thương mại.**
