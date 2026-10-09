import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/local_database.dart';

class BackupService {
  static const maxImportBytes = 10 * 1024 * 1024;

  Future<File> createBackup(LocalDatabase store) async {
    final data = await store.backupSnapshot();
    final folder = await getTemporaryDirectory();
    final name = 'sao_luu_can_lua_${DateTime.now().millisecondsSinceEpoch}.json';
    final f = File('${folder.path}${Platform.pathSeparator}$name');
    return f.writeAsString(jsonEncode(data), encoding: utf8, flush: true);
  }

  Future<Map<String, dynamic>> readBackup(File file) async {
    // Preserve existing API for file-based backups.
    final size = await file.length();
    if (size == 0 || size > maxImportBytes) {
      throw const FormatException('Tệp sao lưu phải nhỏ hơn 10 MB và không được trống.');
    }
    return readBackupBytes(await file.readAsBytes());
  }

  /// Decodes content chosen from Android SAF/iOS document picker without
  /// relying on a real filesystem path (cloud providers can return URIs).
  Map<String, dynamic> readBackupBytes(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > maxImportBytes) {
      throw const FormatException('Tệp sao lưu phải nhỏ hơn 10 MB và không được trống.');
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Tệp sao lưu không đúng cấu trúc.');
      }
      return decoded;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Không đọc được nội dung tệp sao lưu.');
    }
  }
}
