"""Static source sanity and real SQLite migration checks. NOT a Flutter build."""
from pathlib import Path
import re
import sqlite3
import yaml

root = Path(__file__).resolve().parents[1]
files = list(root.glob('lib/**/*.dart')) + list(root.glob('test/*.dart'))
assert len(files) >= 13, len(files)
for f in files:
    src = f.read_text(encoding='utf8')
    for target in re.findall(r"import\s+'(\.{1,2}/[^']+)';", src):
        assert (f.parent / target).resolve().exists(), (f, target)
    assert '\t' not in src, f

raw = (root / 'lib/data/local_database.dart').read_text()
assert 'path, version: 4,' in raw
tables = re.findall(r"database\.execute\('''(CREATE TABLE .*?)'''\)", raw, flags=re.S)
tables = [x for x in tables if not x.startswith('CREATE TABLE IF NOT EXISTS')]
assert len(tables) == 2, tables
index = re.search(r"database\.execute\('(CREATE INDEX [^']+)'\)", raw).group(1)
audit = re.search(r"database\.execute\('''(CREATE TABLE IF NOT EXISTS audit_events.*?\))'''\)", raw, re.S).group(1)

with sqlite3.connect(':memory:') as db:
    db.execute('PRAGMA foreign_keys=ON')
    for ddl in tables: db.execute(ddl)
    db.execute(index)
    db.execute(audit)
    db.execute("INSERT INTO sessions (id,name,customer,price_vnd,decimals,created_at,tare_mode,tare_per_bag_grams) VALUES ('s','Lô theo bao','',6500,2,'2026-10-09','per_bag',250)")
    db.execute("INSERT INTO entries (id,session_id,gross_grams,tare_grams,source,note,created_at,bag_count) VALUES ('e','s',500000,1250,'Nhập tay','','2026-10-09',5)")
    assert db.execute("SELECT tare_mode,tare_per_bag_grams FROM sessions WHERE id='s'").fetchone() == ('per_bag', 250)
    assert db.execute("SELECT bag_count,tare_grams FROM entries WHERE id='e'").fetchone() == (5, 1250)
    db.execute('UPDATE sessions SET price_vnd=7000 WHERE id=?', ('s',))
    assert db.execute("SELECT count(*) FROM entries").fetchone() == (1,)
    db.execute("INSERT INTO sessions (id,name,customer,price_vnd,decimals,created_at,tare_mode,final_tare_grams) VALUES ('late','Trừ cuối','',6500,2,'2026-10-09','after_total',3500)")
    db.execute("INSERT INTO entries (id,session_id,gross_grams,tare_grams,source,note,created_at) VALUES ('e2','late',500000,0,'Nhập tay','','2026-10-09')")
    assert db.execute("SELECT final_tare_grams FROM sessions WHERE id='late'").fetchone() == (3500,)
    try:
        db.execute("INSERT INTO sessions (id,name,customer,price_vnd,decimals,created_at,tare_mode) VALUES ('bad','bad','',1,1,'2026','not_valid')")
    except sqlite3.IntegrityError: pass
    else: raise AssertionError('Invalid tare method accepted by DB')
    db.execute("DELETE FROM sessions WHERE id='s'")
    assert db.execute("SELECT count(*) FROM entries WHERE id='e'").fetchone() == (0,)

# Verify v3 -> v4 migration adds kg/bao without touching any existing weights.
with sqlite3.connect(':memory:') as db:
    db.execute('PRAGMA foreign_keys=ON')
    old_v3_sessions = tables[0].replace(
        ',\n          equivalent_bag_grams INTEGER NOT NULL DEFAULT 50000 CHECK(equivalent_bag_grams > 0 AND equivalent_bag_grams <= 1000000)', '')
    db.execute(old_v3_sessions)
    db.execute(tables[1])
    db.execute(index)
    db.execute(audit)
    db.execute("INSERT INTO sessions (id,name,customer,price_vnd,decimals,created_at,tare_mode,final_tare_grams) VALUES ('v3','Lô cũ','',6000,2,'2026-10-09','after_total',1000)")
    db.execute("INSERT INTO entries (id,session_id,gross_grams,tare_grams,source,note,created_at,bag_count) VALUES ('can','v3',125550,0,'Nhập tay','','2026-10-09',0)")
    db.execute('ALTER TABLE sessions ADD COLUMN equivalent_bag_grams INTEGER NOT NULL DEFAULT 50000 CHECK(equivalent_bag_grams > 0 AND equivalent_bag_grams <= 1000000)')
    assert db.execute("SELECT equivalent_bag_grams FROM sessions WHERE id='v3'").fetchone() == (50000,)
    assert db.execute("SELECT gross_grams FROM entries WHERE id='can'").fetchone() == (125550,)
    db.execute("UPDATE sessions SET equivalent_bag_grams=45000 WHERE id='v3'")
    assert db.execute("SELECT gross_grams FROM entries WHERE id='can'").fetchone() == (125550,)

old_session = '''CREATE TABLE sessions (
 id TEXT PRIMARY KEY, name TEXT NOT NULL, customer TEXT NOT NULL,
 price_vnd INTEGER NOT NULL CHECK(price_vnd >= 0),
 decimals INTEGER NOT NULL CHECK(decimals IN (1,2)), created_at TEXT NOT NULL
)'''
old_entry = '''CREATE TABLE entries (
 id TEXT PRIMARY KEY, session_id TEXT NOT NULL,
 gross_grams INTEGER NOT NULL CHECK(gross_grams > 0),
 tare_grams INTEGER NOT NULL CHECK(tare_grams >= 0 AND tare_grams < gross_grams),
 source TEXT NOT NULL, note TEXT NOT NULL, created_at TEXT NOT NULL,
 FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE
)'''

migration_statements = re.findall(r'database\.execute\("(ALTER TABLE [^\"]+)"\)', raw)
migration_statements += re.findall(r"database\.execute\('(ALTER TABLE [^']+)'\)", raw)
assert len(migration_statements) == 8, migration_statements
for old_version in (1, 2):
    with sqlite3.connect(':memory:') as db:
        db.execute('PRAGMA foreign_keys=ON')
        db.execute(old_session)
        db.execute(old_entry)
        if old_version == 2:
            db.execute("ALTER TABLE sessions ADD COLUMN variety TEXT NOT NULL DEFAULT ''")
            db.execute("ALTER TABLE sessions ADD COLUMN phone TEXT NOT NULL DEFAULT ''")
            db.execute("ALTER TABLE sessions ADD COLUMN paid_vnd INTEGER NOT NULL DEFAULT 0 CHECK(paid_vnd >= 0)")
            db.execute(audit)
        db.execute("INSERT INTO sessions (id,name,customer,price_vnd,decimals,created_at) VALUES ('old','Ông C','',6500,1,'2026-10-09')")
        db.execute("INSERT INTO entries (id,session_id,gross_grams,tare_grams,source,note,created_at) VALUES ('weight','old',500000,2500,'Nhập tay','','2026-10-09')")
        for sql in migration_statements:
            # The code migrates v1->v2 and then v2->v3; v2->v3 skips v1 changes.
            if old_version == 2 and any(c in sql for c in ('COLUMN variety', 'COLUMN phone', 'COLUMN paid_vnd')):
                continue
            db.execute(sql)
        if old_version == 1:
            db.execute(audit)
        row = db.execute("SELECT tare_mode,tare_per_bag_grams,final_tare_grams,equivalent_bag_grams FROM sessions WHERE id='old'").fetchone()
        assert row == ('per_bag', 0, 0, 50000), row
        row = db.execute("SELECT gross_grams,tare_grams,bag_count FROM entries WHERE id='weight'").fetchone()
        assert row == (500000,2500,0), row
        db.execute("UPDATE sessions SET price_vnd=7000 WHERE id='old'")
        assert db.execute("SELECT count(*) FROM entries").fetchone() == (1,)

ui = (root / 'lib/screens/farmer_home_screen.dart').read_text()
for key in ('_currentTare', '_saveBackup', '_importBackup', '_shareReceipt',
            '_editEntry', '_tareSettings', '_saveFinalTare', 'TareMode.afterTotal',
            'TareMode.perBag', 'CẤU HÌNH CÁCH TRỪ BÌ'):
    assert key in ui, key
for key in ('tare_mode', 'tare_per_bag_grams', 'final_tare_grams', 'bag_count'):
    assert key in raw, key
for source in ('lib/services/receipt_service.dart', 'lib/services/csv_service.dart'):
    text = (root/source).read_text(encoding='utf8')
    assert 'WeighSummary.forSession' in text, source
    assert 'TareMode.perBag' in text, source

assert 'textInputAction: TextInputAction.done' in ui
assert 'onSubmitted: (_) => _grossFocus.unfocus()' in ui
assert '_reportPage()' in ui
assert 'equivalent_bag_grams' in raw
assert 'file_picker' in yaml.safe_load((root / 'pubspec.yaml').read_text())['dependencies']
assert yaml.safe_load((root / '.github/workflows/flutter_ci.yml').read_text())
assert not any((root/p).exists() for p in [
    'lib/screens/home_screen.dart', 'lib/screens/barcode_screen.dart',
    'lib/screens/ocr_review_screen.dart', 'lib/core/ocr_parser.dart',
    'lib/services/ocr_service.dart', 'test/ocr_parser_test.dart',
])
deps = yaml.safe_load((root / 'pubspec.yaml').read_text())['dependencies']
assert all(x not in deps for x in ('image_picker', 'google_mlkit_text_recognition', 'mobile_scanner'))
assert all(x not in ui for x in ('_photo(', '_scan()', 'AI OCR', 'OcrService',
                                 'BarcodeScreen', 'CHỤP SỐ CÂN', 'QUÉT QR'))
assert 'NSCameraUsageDescription' in (root / 'scripts/configure_platforms.py').read_text()

print(f'PASS: {len(files)} Dart files/imports; fresh SQLite v4; migration v1/v2/v3 -> v4; ' 
      'preserve existing weights, tare modes, foreign keys, YAML, removed AI modules.')
print('NOT RUN: Flutter analyze/test, APK/IPA build, mobile-device testing (SDK not installed).')
