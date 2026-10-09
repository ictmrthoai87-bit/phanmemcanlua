# HƯỚNG DẪN TRỪ BÌ THEO ĐẦU BAO HOẶC TRỪ SAU

Ứng dụng **CÂN LÚA PRO V0.5** (Flutter Android/iOS, nhập cân thủ công) hỗ trợ **2 chế độ tách biệt** do người dùng chọn cho **từng lô lúa**.

## 1. Trừ bì theo đầu bao

1. Tạo lô mới, chọn **Theo đầu bao**.
2. Trong **Cân nhanh**, nhấn **CẤU HÌNH BÌ** và nhập số kg bì một bao, ví dụ `0,5` kg/bao (hoặc `0,25` nếu chọn 2 số lẻ).
3. Mỗi lần cân, nhập số kg cân tổng và **số bao trong lượt đó**.
4. Phần mềm tự trừ: **bì của lượt = số bao × kg bì mỗi bao**. Khối lượng thực lượt = khối lượng cân lượt − bì lượt.
5. Lưu lần cân; sổ hiển thị số bao, tổng bì và cân thực. Tổng tiền được tính **một lần từ tổng khối lượng thực nhận**.

Ví dụ: cân 500,0 kg, 5 bao, bì 0,5 kg/bao → trừ 2,5 kg, còn 497,5 kg.

**Lưu ý:** Nếu thay đổi mức kg bì/bao giữa vụ, các lượt đã lưu vẫn giữ nguyên bì và số tiền tại thời điểm cân; chỉ lượt mới nhận mức bì mới. Người dùng có thể sửa rõ từng lượt nếu cần.

## 2. Trừ bì sau khi cân xong

1. Tạo lô mới, chọn **Trừ cuối**, hoặc mở **CẤU HÌNH BÌ** trước khi nhập lượt đầu.
2. Nhập từng số cân; các lượt này **chưa trừ bì**.
3. Sau khi cân xong, nhập **Tổng bì trừ sau (kg)** và nhấn **LƯU BÌ**.
4. Phần mềm tính **thực nhận = tổng số cân − tổng bì cuối**, không trừ bì ở bất kỳ lượt riêng nào.
5. Thành tiền = thực nhận × đơn giá đ/kg, làm tròn tới đồng trên tổng thực nhận.

Ví dụ: lượt 1 = 500,0 kg; lượt 2 = 300,0 kg; tổng bì cuối = 3,5 kg → thực nhận = 796,5 kg; giá 6.500 đ/kg → thành tiền **5.177.250 đ**.

**Lưu ý:** Có thể lưu nhiều lượt trước và nhập bì cuối sau. Bì cuối = 0 tức là chưa khấu trừ; trước khi xác nhận giao dịch, cần kiểm tra bì cuối đã nhập chính xác.

## 3. An toàn dữ liệu

- Phương pháp trừ bì được lưu **riêng cho mỗi lô**; không thay đổi tất cả khách hàng.
- Khi lô đã có lượt cân, **không đổi chế độ** để tránh trừ hai lần hoặc mất dấu bì cũ. Nếu cần cách tính khác, tạo lô mới.
- Không chấp nhận số bao không hợp lệ, bì vượt hoặc bằng cân tổng, hay khối lượng âm.
- Phiếu cân và CSV đều ghi **chế độ trừ bì, tổng cân, tổng bì, khối lượng thực và thành tiền**.
- Lượt cân lịch sử V0.4 được giữ lại trong chế độ **Theo đầu bao** mặc định; bì đã trừ ở lượt cũ không thay đổi, số bao cũ có thể bằng 0 vì trước đây chưa lưu trường này.
- Trước khi cập nhật ứng dụng, hãy sao lưu dữ liệu từ mục **Tiện ích**.

## 4. Hai số lẻ

Cài trong **Cân nhanh** → **1 số lẻ / 2 số lẻ**. Nếu có dữ liệu hoặc mức bì cần 2 chữ số thập phân, phần mềm ngăn chuyển về 1 chữ số để không làm sai dữ liệu. Nội bộ lưu cân bằng **gam nguyên** và tiền bằng **đồng nguyên**.

## Trạng thái hiện tại

Đây là bộ mã nguồn; chưa tạo file APK/IPA đã ký hoặc thử nghiệm trên điện thoại thật. Cần chạy `flutter analyze`, `flutter test` và build trên máy có Flutter SDK trước khi phát hành.
