# FIX BUILD V0.5.5 – Flutter analyze

## Nguyen nhan

Log `build_20261010_004016.log` bao loi:
- `farmer_home_screen.dart:599` thieu dau `)` ket thuc `Expanded`, dan den them hai loi phan tich.
- `test/widget_test.dart` Flutter sinh khi chay `flutter create` su dung `MyApp` khong co trong du an. Lop dung la `LuaCanProApp`.
- Ba canh bao if thieu cap ngoac nhon.

## Cap nhat tren Windows

1. Giai nen ZIP ban va, chep nguyen bo noi dung thu muc CAN_LUA_PRO vao thu muc CAN_LUA_PRO hien tai va chon ghi de.
2. Khong xoa `%LOCALAPPDATA%\CLB` vi Flutter 3.47.7, JDK 17 va Android SDK API 36 da cai dung o buoc truoc.
3. Chay `BUILD_APK_WINDOWS.bat` trong thu muc phan mem.
4. Neu thanh cong, lay file `output\CAN_LUA_PRO_ANDROID.apk`.
5. Neu van co loi, gui file `output\build_*.log` moi nhat.

## Nhung file duoc sua

- `lib/screens/farmer_home_screen.dart`: sua ngoac va canh bao.
- `test/widget_test.dart`: them test dung ten app.
- `scripts/build_apk_windows.ps1`: dam bao `flutter create` khong su dung test mau MyApp.
- `BUILD_APK_WINDOWS.bat`: cap nhat nhan dien ban va thong bao loi.
- `pubspec.yaml`: tang phien ban len 0.5.5+10.
- `.github/workflows/flutter_ci.yml`: don test template neu xuat hien.

**Chua co APK da bien dich trong goi ZIP.** De xuat APK can chay build tren Windows co Flutter va Android SDK. File APK dang o che do thu nghiem, chua ky release cho phat hanh thuong mai.
