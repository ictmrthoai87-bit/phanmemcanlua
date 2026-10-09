import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lua_can_pro/services/backup_service.dart';

void main() {
  final service = BackupService();

  test('Đọc JSON sao lưu từ dữ liệu chọn qua Files', () {
    final source = <String, dynamic>{'sessions': <dynamic>[], 'entries': <dynamic>[]};
    final decoded = service.readBackupBytes(utf8.encode(jsonEncode(source)));
    expect(decoded, source);
  });

  test('Từ chối bản sao lưu trống, dữ liệu không phải object hoặc JSON hỏng', () {
    expect(() => service.readBackupBytes([]), throwsFormatException);
    expect(() => service.readBackupBytes(utf8.encode('[]')), throwsFormatException);
    expect(() => service.readBackupBytes(utf8.encode('{not json')), throwsFormatException);
  });

  test('Từ chối tệp trên 10 MB', () {
    expect(() => service.readBackupBytes(List<int>.filled(BackupService.maxImportBytes + 1, 0)), throwsFormatException);
  });
}
