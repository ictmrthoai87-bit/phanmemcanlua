# KẾT QUẢ KIỂM TRA — CÂN LÚA PRO V0.4 (09/10/2026)

## Đã thực hiện

- Kiểm tra imports tương đối sau khi xóa mô-đun OCR/QR và màn hình cũ.
- Kiểm tra `pubspec.yaml` không còn ba gói `image_picker`, `google_mlkit_text_recognition`, `mobile_scanner`.
- Kiểm tra màn hình nhà nông không còn nút chụp ảnh/QR hoặc luồng nhận diện.
- Chạy trực tiếp truy vấn SQLite trong bộ nhớ, kiểm tra cập nhật giá không xóa lượt cân, migrate dữ liệu bản cũ và xóa theo khóa ngoại.
- Kiểm tra bộ thiết lập native xóa quyền CAMERA trong AndroidManifest.xml và mô tả camera/thư viện ảnh trên iOS Info.plist.
- Duy trì dữ liệu `source` lịch sử nguyên dạng; khi nhập mới nguồn được ghi `Nhập tay`.

## Chưa thực hiện

- Không có Flutter/Dart SDK: chưa chạy `flutter analyze`, `flutter test`, `flutter build apk/ipa`.
- Chưa kiểm thử trên điện thoại Android/iOS thực, chưa ký phát hành thương mại.

Kiểm thử tĩnh: `python scripts/static_verify.py`; cấu hình native `python scripts/configure_platforms.py` sau khi `flutter create`.
