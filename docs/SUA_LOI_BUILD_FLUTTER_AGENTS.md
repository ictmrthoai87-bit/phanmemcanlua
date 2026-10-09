# Sua loi BUILD THAT BAI: Cannot find path flutter\.agents

## Nguyen nhan

Ban build cu su dung PowerShell `Expand-Archive` de giai nen Flutter SDK vao thu muc `.build_tools` nam sau duong dan du an rat dai. Khi xu ly mot thu muc nhu `flutter\.agents`, PowerShell da bao loi va dung o buoc 2/7. Day la loi *cai bo cong cu build*, khong phai loi nhap so can, tinh gia, hay tru bi.

Ma build V0.5.1 duoc sua nhu sau:

- Tai va giai nen Flutter vao `%LOCALAPPDATA%\CLB\flutter` bang `tar.exe` tren Windows 10/11, khong dung `Expand-Archive` cho Flutter.
- Neu file `.build_tools\flutter_sdk.zip` cua ban cu van con va khop SHA256 chinh thuc, su dung lai de tranh tai them.
- Tao project Android trong `%LOCALAPPDATA%\CLB\project` de tranh duong dan `D:\soft\...` qua dai.
- Uu tien JDK 17 (chap nhan JDK 21); neu chi co Java 25 thi thu cai Temurin JDK 17 bang winget.
- Sua loi PowerShell `$Host` la bien he thong khong duoc gan lai khi phat hien Android command-line tools (doi thanh `$hostOsNode`).
- Giu lai test/analyze; neu that bai thi dung, khong tao APK gia.

## Cach 1: Sua truc tiep bo V0.5 dang co (khuyen dung)

1. Dong cua so BUILD dang chay.
2. Tai tep `CAN_LUA_PRO_FIX_BUILD_V0_5_1_PATCH.zip` va giai nen. Trong goi se co `scripts\build_apk_windows.ps1`.
3. Sao chep **thu muc `scripts`** trong goi patch vao thu muc `CAN_LUA_PRO` da giai nen tren may, chon **ghi de tep** `scripts\build_apk_windows.ps1` cu.
4. Nhan dup `BUILD_APK_WINDOWS.bat` (tep BAT cu khong can sua).
5. Khi Android SDK hoi chap nhan license, doc va nhap `y` neu dong y.
6. Sau khi BUILD THANH CONG, lay `output\CAN_LUA_PRO_ANDROID.apk` de cai Android.

**Khong xoa** thu muc `.build_tools` cu neu con tep `flutter_sdk.zip`: script moi se kiem tra va tai su dung neu con nguyen ven. Viec script tu tao workspace khac KHONG xoa tep goc hay lich su can tren dien thoai.

## Cach 2: Tai lai toan bo source da sua

Tai tep `CAN_LUA_PRO_V0_5_1_SUA_LOI_BUILD_WINDOWS.zip` va giai nen, sau do chay `CAN_LUA_PRO\BUILD_APK_WINDOWS.bat`. Duong dan giai nen dai nhu `D:\soft\PHAM MEM CHUNG\...` van duoc vi SDK va project build tam nay nam ngoai thu muc tren, tuy nhien nen giai nen bo source o mot noi ngan de de quan ly.

## Neu gap loi tiep theo

- `Thieu JDK 17/21`: cai Temurin JDK 17 (https://adoptium.net/) roi chay lai.
- `Khong cai duoc Android platforms/build-tools`: kiem tra mang, proxy/firewall va dung luong o dia.
- `Chua chap nhan Android SDK licenses`: chay lai va chap nhan sau khi doc cac license.
- `Flutter analyze` / `flutter test` / `Gradle` fail: gui noi dung **50 dong cuoi** cua `output\build_*.log` va ten buoc that bai; bo build nay khong gia mao thanh cong.
- Neu dung luong dia it: can bo nho cho Flutter, Android SDK va Gradle; hay giai phong dung luong truoc.

### Lay 50 dong cuoi file log

Mo PowerShell tai thu muc `CAN_LUA_PRO`:

```powershell
Get-Content (Get-ChildItem .\output\build_*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName -Tail 50
```

**Ghi chu:** Chua co APK duoc bien dich trong bo ZIP nay; APK duoc tao tren may Windows cua ban khi bo build chay thanh cong. iOS van can Mac/Xcode va Apple signing.
