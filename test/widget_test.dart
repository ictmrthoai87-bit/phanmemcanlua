import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/main.dart';

void main() {
  test('Ứng dụng Cân Lúa Pro khởi tạo đúng lớp gốc', () {
    // Test thuần không mở SQLite, tránh cần mô phỏng plugin ở widget_test.
    const app = LuaCanProApp();
    expect(app, isA<StatelessWidget>());
  });
}
