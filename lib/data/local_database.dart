import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/weigh_models.dart';

class LocalDatabase {
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'lua_can_pro_v1.db');
    _db = await openDatabase(
      path, version: 4,
      onConfigure: (database) async => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, version) async {
        await database.execute('''CREATE TABLE sessions (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, customer TEXT NOT NULL,
          price_vnd INTEGER NOT NULL CHECK(price_vnd >= 0),
          decimals INTEGER NOT NULL CHECK(decimals IN (1,2)),
          created_at TEXT NOT NULL,
          variety TEXT NOT NULL DEFAULT '', phone TEXT NOT NULL DEFAULT '',
          paid_vnd INTEGER NOT NULL DEFAULT 0 CHECK(paid_vnd >= 0),
          tare_mode TEXT NOT NULL DEFAULT 'per_bag' CHECK(tare_mode IN ('per_bag','after_total')),
          tare_per_bag_grams INTEGER NOT NULL DEFAULT 0 CHECK(tare_per_bag_grams >= 0),
          final_tare_grams INTEGER NOT NULL DEFAULT 0 CHECK(final_tare_grams >= 0),
          equivalent_bag_grams INTEGER NOT NULL DEFAULT 50000 CHECK(equivalent_bag_grams > 0 AND equivalent_bag_grams <= 1000000)
        )''');
        await database.execute('''CREATE TABLE entries (
          id TEXT PRIMARY KEY, session_id TEXT NOT NULL,
          gross_grams INTEGER NOT NULL CHECK(gross_grams > 0),
          tare_grams INTEGER NOT NULL CHECK(tare_grams >= 0 AND tare_grams < gross_grams),
          source TEXT NOT NULL, note TEXT NOT NULL, created_at TEXT NOT NULL,
          bag_count INTEGER NOT NULL DEFAULT 0 CHECK(bag_count >= 0),
          FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE
        )''');
        await database.execute('CREATE INDEX idx_entries_session ON entries(session_id, created_at)');
        await _createAuditTable(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute("ALTER TABLE sessions ADD COLUMN variety TEXT NOT NULL DEFAULT ''");
          await database.execute("ALTER TABLE sessions ADD COLUMN phone TEXT NOT NULL DEFAULT ''");
          await database.execute('ALTER TABLE sessions ADD COLUMN paid_vnd INTEGER NOT NULL DEFAULT 0 CHECK(paid_vnd >= 0)');
          await _createAuditTable(database);
        }
        if (oldVersion < 3) {
          await database.execute("ALTER TABLE sessions ADD COLUMN tare_mode TEXT NOT NULL DEFAULT 'per_bag' CHECK(tare_mode IN ('per_bag','after_total'))");
          await database.execute('ALTER TABLE sessions ADD COLUMN tare_per_bag_grams INTEGER NOT NULL DEFAULT 0 CHECK(tare_per_bag_grams >= 0)');
          await database.execute('ALTER TABLE sessions ADD COLUMN final_tare_grams INTEGER NOT NULL DEFAULT 0 CHECK(final_tare_grams >= 0)');
          await database.execute('ALTER TABLE entries ADD COLUMN bag_count INTEGER NOT NULL DEFAULT 0 CHECK(bag_count >= 0)');
        }
        if (oldVersion < 4) {
          await database.execute('ALTER TABLE sessions ADD COLUMN equivalent_bag_grams INTEGER NOT NULL DEFAULT 50000 CHECK(equivalent_bag_grams > 0 AND equivalent_bag_grams <= 1000000)');
        }
      },
    );
    return _db!;
  }

  static Future<void> _createAuditTable(DatabaseExecutor database) async {
    await database.execute('''CREATE TABLE IF NOT EXISTS audit_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT NOT NULL,
      session_id TEXT NOT NULL, entry_id TEXT NOT NULL DEFAULT '',
      before_json TEXT NOT NULL DEFAULT '', after_json TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL
    )''');
  }

  Future<void> _audit(Transaction txn, String action, String sessionId,
      {String entryId = '', Map<String, Object?>? before,
      Map<String, Object?>? after}) async {
    await txn.insert('audit_events', {
      'action': action, 'session_id': sessionId, 'entry_id': entryId,
      'before_json': before == null ? '' : jsonEncode(before),
      'after_json': after == null ? '' : jsonEncode(after),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<WeighSession>> sessions() async {
    final database = await db;
    return (await database.query('sessions', orderBy: 'created_at DESC'))
        .map(WeighSession.fromMap).toList();
  }

  Future<void> upsertSession(WeighSession session) async {
    final database = await db;
    if (session.equivalentBagGrams <= 0 || session.equivalentBagGrams > 1000000) {
      throw const FormatException('Số kg mỗi bao quy đổi phải lớn hơn 0 và tối đa 1.000.');
    }
    if (session.tarePerBagGrams < 0 || session.finalTareGrams < 0) {
      throw const FormatException('Số bì không được âm.');
    }
    await database.transaction((txn) async {
      final before = await txn.query('sessions', where: 'id = ?', whereArgs: [session.id]);
      final existingEntries = await txn.query('entries',
        columns: ['gross_grams'], where: 'session_id = ?', whereArgs: [session.id]);
      if (before.isNotEmpty && existingEntries.isNotEmpty &&
          before.single['tare_mode'] != session.tareMode.dbValue) {
        throw const FormatException(
          'Lô đã có lượt cân; không đổi chế độ bì để tránh tính sai. Hãy tạo lô mới.');
      }
      if (session.tareMode == TareMode.afterTotal) {
        final totalGross = existingEntries.fold<int>(0,
          (sum, e) => sum + (e['gross_grams'] as int));
        if (session.finalTareGrams != 0 &&
            (totalGross == 0 || session.finalTareGrams >= totalGross)) {
          throw const FormatException('Bì trừ cuối phải nhỏ hơn tổng số cân.');
        }
      }
      if (before.isEmpty) {
        await txn.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
      } else {
        // REPLACE would delete all child weigh entries by FK cascade.
        await txn.update('sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
      }
      await _audit(txn, before.isEmpty ? 'create_session' : 'update_session', session.id,
          before: before.isEmpty ? null : before.single, after: session.toMap());
    });
  }

  Future<void> deleteSession(String id) async {
    final database = await db;
    await database.transaction((txn) async {
      final sessions = await txn.query('sessions', where: 'id = ?', whereArgs: [id]);
      if (sessions.isEmpty) return;
      final rows = await txn.query('entries', where: 'session_id = ?', whereArgs: [id]);
      await txn.delete('sessions', where: 'id = ?', whereArgs: [id]);
      // Privacy: do not retain deleted customer's name/phone in the audit log.
      await txn.delete('audit_events', where: 'session_id = ?', whereArgs: [id]);
      await _audit(txn, 'delete_session', id,
          after: {'entries_removed': rows.length});
    });
  }

  Future<List<WeighEntry>> entries(String sessionId) async {
    final database = await db;
    return (await database.query('entries', where: 'session_id = ?',
      whereArgs: [sessionId], orderBy: 'created_at ASC'))
        .map(WeighEntry.fromMap).toList();
  }

  Future<void> insertEntries(List<WeighEntry> rows) async {
    if (rows.isEmpty) return;
    final database = await db;
    await database.transaction((txn) async {
      for (final e in rows) {
        final sessions = await txn.query('sessions',
          columns: ['tare_mode'], where: 'id = ?', whereArgs: [e.sessionId]);
        if (sessions.length != 1) throw const FormatException('Không tìm thấy lô lúa.');
        if (e.bagCount < 0 ||
            (sessions.single['tare_mode'] == TareMode.afterTotal.dbValue && e.tareGrams != 0)) {
          throw const FormatException('Bì của lượt cân không đúng chế độ đã chọn.');
        }
        await txn.insert('entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
        await _audit(txn, 'create_entry', e.sessionId, entryId: e.id, after: e.toMap());
      }
    });
  }

  Future<void> updateEntry(WeighEntry entry) async {
    final database = await db;
    await database.transaction((txn) async {
      final before = await txn.query('entries', where: 'id = ?', whereArgs: [entry.id]);
      if (before.length != 1 || before.single['session_id'] != entry.sessionId) {
        throw const FormatException('Không tìm thấy lượt cân cần sửa.');
      }
      if (entry.grossGrams <= 0 || entry.tareGrams < 0 ||
          entry.grossGrams <= entry.tareGrams || entry.bagCount < 0) {
        throw const FormatException('Số cân phải lớn hơn bì.');
      }
      final parent = await txn.query('sessions', where: 'id = ?', whereArgs: [entry.sessionId]);
      if (parent.isEmpty) throw const FormatException('Lô lúa không tồn tại.');
      if (parent.single['tare_mode'] == TareMode.afterTotal.dbValue) {
        if (entry.tareGrams != 0) {
          throw const FormatException('Lô trừ bì cuối không trừ tại từng lượt.');
        }
        final others = await txn.query('entries', columns: ['gross_grams'],
          where: 'session_id = ? AND id != ?', whereArgs: [entry.sessionId, entry.id]);
        final totalGross = others.fold<int>(entry.grossGrams,
          (sum, row) => sum + (row['gross_grams'] as int));
        final finalTare = parent.single['final_tare_grams'] as int;
        if (totalGross <= finalTare) {
          throw const FormatException('Số cân còn lại không lớn hơn tổng bì cuối.');
        }
      }
      await txn.update('entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
      await _audit(txn, 'update_entry', entry.sessionId, entryId: entry.id,
          before: before.single, after: entry.toMap());
    });
  }

  Future<void> deleteEntry(String id) async {
    final database = await db;
    await database.transaction((txn) async {
      final before = await txn.query('entries', where: 'id = ?', whereArgs: [id]);
      if (before.isEmpty) return;
      final sessionId = before.single['session_id'] as String;
      final parents = await txn.query('sessions', where: 'id = ?', whereArgs: [sessionId]);
      if (parents.isNotEmpty && parents.single['tare_mode'] == TareMode.afterTotal.dbValue) {
        final finalTare = parents.single['final_tare_grams'] as int;
        final others = await txn.query('entries', columns: ['gross_grams'],
          where: 'session_id = ? AND id != ?', whereArgs: [sessionId, id]);
        final remainingGross = others.fold<int>(0,
          (sum, row) => sum + (row['gross_grams'] as int));
        if (finalTare != 0 && remainingGross <= finalTare) {
          throw const FormatException('Hãy giảm bì trừ cuối trước khi xóa lượt cân này.');
        }
      }
      await txn.delete('entries', where: 'id = ?', whereArgs: [id]);
      await _audit(txn, 'delete_entry', before.single['session_id'] as String,
          entryId: id, before: before.single);
    });
  }

  Future<Map<String, Object?>> backupSnapshot() async {
    final database = await db;
    return {
      'format': 'lua_can_pro_backup', 'version': 3,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'sessions': await database.query('sessions', orderBy: 'created_at'),
      'entries': await database.query('entries', orderBy: 'created_at'),
    };
  }

  /// Explicit user confirmation is required before calling this method.
  /// Parse and validate entirely before clearing existing data.
  Future<void> restoreSnapshot(Map<String, dynamic> snapshot) async {
    if (snapshot['format'] != 'lua_can_pro_backup' ||
        (snapshot['version'] != 1 && snapshot['version'] != 2 && snapshot['version'] != 3)) {
      throw const FormatException('Tệp sao lưu không đúng định dạng Cân Lúa Pro.');
    }
    final rawSessions = snapshot['sessions'];
    final rawEntries = snapshot['entries'];
    if (rawSessions is! List || rawEntries is! List ||
        rawSessions.length > 20000 || rawEntries.length > 300000) {
      throw const FormatException('Tệp sao lưu thiếu hoặc quá lớn.');
    }
    final sessions = <WeighSession>[];
    final entries = <WeighEntry>[];
    try {
      for (final row in rawSessions) {
        final session = WeighSession.fromMap(Map<String, Object?>.from(row as Map));
        if (session.id.isEmpty || session.name.isEmpty || session.priceVnd < 0 ||
            session.paidVnd < 0 || session.tarePerBagGrams < 0 ||
            session.finalTareGrams < 0 ||
            session.equivalentBagGrams <= 0 ||
            session.equivalentBagGrams > 1000000 ||
            (session.decimals != 1 && session.decimals != 2)) {
          throw const FormatException('Phiên trong sao lưu không hợp lệ.');
        }
        sessions.add(session);
      }
      final ids = sessions.map((e) => e.id).toSet();
      if (ids.length != sessions.length) throw const FormatException('Mã phiên bị trùng.');
      final entryIds = <String>{};
      for (final row in rawEntries) {
        final entry = WeighEntry.fromMap(Map<String, Object?>.from(row as Map));
        if (!ids.contains(entry.sessionId) || entry.id.isEmpty || !entryIds.add(entry.id) ||
            entry.grossGrams <= 0 || entry.tareGrams < 0 || entry.netGrams <= 0 ||
            entry.bagCount < 0) {
          throw const FormatException('Lượt cân trong sao lưu không hợp lệ.');
        }
        entries.add(entry);
      }
      for (final session in sessions) {
        final sessionEntries = entries.where((e) => e.sessionId == session.id).toList();
        final gross = sessionEntries.fold<int>(0, (sum, e) => sum + e.grossGrams);
        if (session.tareMode == TareMode.afterTotal &&
            (sessionEntries.any((e) => e.tareGrams != 0) ||
             (session.finalTareGrams != 0 &&
              (gross == 0 || session.finalTareGrams >= gross)))) {
          throw const FormatException('Tổng bì cuối trong bản sao lưu không hợp lệ.');
        }
      }
    } on FormatException { rethrow; }
      catch (_) { throw const FormatException('Dữ liệu sao lưu bị lỗi hoặc không tương thích.'); }
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('entries');
      await txn.delete('sessions');
      await txn.delete('audit_events');
      for (final s in sessions) { await txn.insert('sessions', s.toMap()); }
      for (final e in entries) { await txn.insert('entries', e.toMap()); }
      await _audit(txn, 'restore_backup', '', after: {
        'sessions': sessions.length, 'entries': entries.length,
      });
    });
  }

  Future<List<Map<String, Object?>>> auditEvents({int limit = 200}) async {
    final database = await db;
    return database.query('audit_events', orderBy: 'id DESC', limit: limit);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
