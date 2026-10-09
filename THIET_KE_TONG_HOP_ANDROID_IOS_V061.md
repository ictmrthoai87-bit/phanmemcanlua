# CÂN LÚA PRO V0.6.1 — ĐẶC TẢ TỔNG HỢP ANDROID VÀ IOS

**Mục tiêu:** Một bộ mã nguồn Flutter chung cho Android/iOS, giúp nông dân nhập cân bằng một tay, tự tính cân – trừ bì – thành tiền, lưu lịch sử và báo cáo kg/bao theo từng lượt.

## 1. Cách thao tác theo hình người dùng cung cấp

1. Chọn hoặc tạo **lô lúa**. Nếu dùng trừ bì theo đầu bao, cấu hình kg bì/bao và nhập **số bao thực của lượt** (mặc định 1).
2. Chạm vào **NHẬP SỐ CÂN**, gõ số kg (ví dụ `125,55`).
3. **Nhấn dấu ✓/Done trên bàn phím**. Android dùng `TextInputAction.done` và `onSubmitted` (iPhone/iPad có thêm biểu tượng ✓ trong ô kg) để gọi chính hàm `_addManual()` đang được nút lưu dự phòng sử dụng.
4. Ứng dụng kiểm tra dữ liệu, cảnh báo cân trùng trong 90 giây, lưu SQLite thành một lượt mới; xóa ô cân và đưa con trỏ về ô cân khi thành công. Không ghi trùng khi tác vụ lưu đang thực hiện. Nếu nhập sai, có thể sửa/xóa một lượt trong sổ.
5. Tổng kg, tổng tiền, danh sách và báo cáo được cập nhật từ SQLite. Không cần chạm thêm nút LƯU khi đã nhấn ✓. **Hình dạng/phím ✓, Done hoặc Xong do bàn phím hệ điều hành quyết định**. Riêng bàn phím số thập phân của iOS thường không có phím Done: nhấn **biểu tượng ✓ ngay trong ô nhập kg**, chỉ cần một chạm để lưu. Nút LƯU bên dưới cũng là phương án dự phòng.

**Lưu ý:** Nhấn ✓ ở ô *số kg* để lưu lượt. Khi đang chỉnh ô số bao, phải chuyển về ô số kg rồi nhấn ✓. Cách hoạt động trên Android và iOS phụ thuộc bàn phím được cài trên máy.

## 2. Cấu hình quy đổi bao

- **Mặc định:** 1 bao quy đổi = **50 kg**. Đây là giá trị đề xuất để bắt đầu, không cố định. Mỗi lô có thể đặt 40 kg/bao, 45 kg/bao, 60 kg/bao... trong tab **BÁO CÁO**.
- **Bao thực:** số bao người dùng nhập để tính bì trong chế độ trừ theo đầu bao; không được lấy bao quy đổi thay cho bao thực.
- **Bao quy đổi:** số lượng tương đương dựa theo kg, có 2 số lẻ để HIỂN THỊ. Dữ liệu khối lượng lưu chính xác theo gram nguyên.
- Công thức: `bao_quy_đổi = kg_dùng_để_quy_đổi / kg_mỗi_bao`, và ghi thêm `bao_tròn + kg_lẻ` chính xác.
- Giá trị đổi kg/bao được lưu riêng trên lô trong `sessions.equivalent_bag_grams` (SQLite schema v4). Đổi kg/bao chỉ đổi hiển thị/báo cáo, **không đổi cân gốc, bì hoặc tiền**.

## 3. Hai cách trừ bì không được cộng chồng

**Trừ theo đầu bao:** Người dùng nhập số bao thực mỗi lượt. `bì_lượt = số_bao_thực × bì_1_bao` và `kg_thực_lượt = kg_cân_lượt − bì_lượt`. Báo cáo bao quy đổi *từng lượt* từ kg thực, tổng từ tổng kg thực.

**Trừ cuối:** Từng lượt chỉ lưu **kg cân tổng**, không tự phân bổ bì cuối sang lượt. Báo cáo bao quy đổi **từng lượt tạm tính từ kg cân tổng** và ghi rõ "chưa trừ bì". Sau khi tổng hợp, nhập `tổng_bì_cuối`; báo cáo lô lấy `tổng_kg_thực = tổng_kg_cân − bì_cuối` và quy đổi lại bao **một lần**. Nếu chưa nhập bì thì số liệu lô là *tạm tính*.

## 4. Màn hình giao diện

- **CÂN NHANH:** tên lô, tổng cân/tổng kg thực, đơn giá, tiền còn lại, ô nhập kg lớn, nút ✓ trên bàn phím để lưu, bì, số bao, 1/2 số lẻ, danh sách lượt mới nhất.
- **BÁO CÁO:** toàn bộ lượt theo thứ tự, thời gian, kg tổng, bì, kg thực (hoặc chưa trừ bì cuối), bao quy đổi từng lượt, tổng số lượt, tổng kg, tổng bì, tổng kg thực, bao tương đương, báo cáo CSV, chia sẻ phiếu.
- **SỔ CÂN:** tìm lô, chọn lô, sửa, xóa; phân tách mỗi khách/chuyến cân.
- **TIỆN ÍCH:** chia sẻ phiếu, xuất CSV, sao lưu JSON, khôi phục; lịch sử thay đổi.

## 5. Ví dụ tính

**Lô A (bì theo đầu bao, 0,50 kg/bao, 50 kg/bao quy đổi):**

| Lượt | Cân tổng | Bao thực | Bì | Kg thực | Bao quy đổi |
|---|---:|---:|---:|---:|---:|
| 1 | 125,50 kg | 2 | 1,00 kg | 124,50 kg | 2,49 |
| 2 | 80,00 kg | 1 | 0,50 kg | 79,50 kg | 1,59 |
| **Tổng** | **205,50 kg** | **3** | **1,50 kg** | **204,00 kg** | **4,08** |

**Lô B (trừ cuối, 50 kg/bao quy đổi):** lượt 1 = 120 kg (2,40 bao tạm), lượt 2 = 80 kg (1,60 bao tạm). Tổng cân 200 kg; tổng bì cuối 3,50 kg; **thực 196,50 kg = 3,93 bao**.

Làm tròn từng lượt khi hiển thị có thể khiến tổng số bao lẻ khác tổng số bao quy đổi chính thức do làm tròn; **tổng luôn tính từ gram thực**, không cộng các số bao hiển thị đã làm tròn.

## 6. Kiến trúc/kỹ thuật

- Flutter/Dart, giao diện tiếng Việt; SQLite cục bộ; không bắt buộc Internet để nhập/lưu/xem.
- Mô hình: `WeighSession` (lô) – `WeighEntry` (lượt) – `WeighSummary` – `BagConversion`.
- `lib/screens/farmer_home_screen.dart`: nút ✓ bàn phím và bốn màn hình.
- `lib/core/bag_conversion.dart`: phép tính bao chính xác nguyên gram.
- `lib/data/local_database.dart`: schema v4, nâng cấp v1/v2/v3 → v4 không xóa dữ liệu.
- `lib/services/csv_service.dart`, `receipt_service.dart`: từng lượt và tổng bao quy đổi.
- `test/bag_conversion_test.dart`: các tình huống quy đổi, hai cách bì, CSV, tương thích sao lưu cũ.
- `test/widget_test.dart` và các kiểm thử từ phiên bản trước được giữ lại.

**Phát triển ứng dụng phát hành thương mại:** cần bản APK ký bằng khóa release riêng, IPA được ký bằng chứng chỉ Apple, kiểm thử trên thiết bị, chính sách bảo mật, sao lưu/đồng bộ, quy trình phát hành và hỗ trợ khách hàng. Phiếu cân trong ứng dụng hiện là phiếu thông tin, không phải hóa đơn điện tử có chứng nhận.

## 7. Tạo file cài đặt

**Android – Windows:** Nháy đúp `BUILD_APK_WINDOWS.bat`; lấy `output/CAN_LUA_PRO_ANDROID.apk` khi hoàn tất. Công cụ cài Java/Flutter/Android SDK theo luồng sẵn có; có thể cần mạng cho lượt build đầu tiên.

**iPhone/iPad – macOS:** Chạy `bash BUILD_IOS_MAC.command` trên Mac có Xcode/Flutter. Dùng Xcode + Apple ID để cài thử; phát hành bằng TestFlight/App Store cần tài khoản và chứng chỉ phù hợp. **Windows không thể trực tiếp biên dịch IPA được ký bằng Xcode.**

## 8. Giới hạn kiểm thử hiện tại

Đã kiểm tra cú pháp nguồn theo quy tắc tĩnh, chạy mô phỏng nâng cấp SQLite, soát nội dung các tệp. **Chưa chạy được `flutter analyze`, `flutter test`, Gradle assembleRelease hay Xcode trong môi trường tạo gói này**, do không có Flutter SDK/Xcode. Cần build trên Windows/Mac và gửi log nếu còn lỗi; chưa thể bảo đảm APK/IPA cài chạy thực tế.
