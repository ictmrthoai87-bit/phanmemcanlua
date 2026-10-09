import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/core/app_info.dart';

void main() {
  test('Thông tin phiên bản và biên tập được hiển thị đúng', () {
    expect(AppInfo.name, 'CÂN LÚA PRO');
    expect(AppInfo.version, '0.6.3');
    expect(AppInfo.buildNumber, 19);
    expect(AppInfo.editorLabel, 'Edit: Lê Ngọc Thoại');
    expect(AppInfo.titleWithVersion, contains('V0.6.3'));
  });
}
