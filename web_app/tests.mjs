import test from 'node:test';
import assert from 'node:assert/strict';
import {VERSION, gramsFromInput, createLot, normalizeLot, summarize, fmtKg, csvForLot, receiptForLot, checkedBackup, validateLot, orderEntries, validateEntry} from './model.mjs';
const mk=(g,b=1,id='e1')=>({id,lotId:'lot1',grossGrams:g,bagCount:b,note:'',createdAt:new Date().toISOString()});
const lot=(fields={})=>({...createLot('Lô kiểm thử'),...fields});

test('bản 0.7.2',()=>assert.equal(VERSION,'0.7.2'));
test('125,50 thành 125500 gram',()=>assert.equal(gramsFromInput('125,50'),125500));
test('chọn 1 số lẻ chặn giá trị 2 số lẻ',()=>assert.throws(()=>gramsFromInput('125,55',1)));
test('không cho cân 0 hoặc giá trị âm',()=>{assert.throws(()=>gramsFromInput('0'));assert.throws(()=>gramsFromInput('-1'));});
test('mặc định mỗi lần lưu đúng 1 bao, không dùng kg/50',()=>{
 const l=lot();assert.equal(l.bagsPerEntry,1);assert.equal('kgPerBagGrams' in l,false);
 const s=summarize(l,[mk(43000),mk(60000,1,'e2')]);
 assert.equal(s.count,2);assert.equal(s.bagsActual,2);assert.equal(s.gross,103000);
});
test('bì theo đầu bao mỗi lượt 1 bao',()=>{
 const l=lot({tareMode:'per_bag',tarePerBagGrams:500,priceVnd:6500});
 const s=summarize(l,[mk(125500),mk(80000,1,'e2')]);
 assert.equal(s.bagsActual,2);assert.equal(s.tare,1000);assert.equal(s.net,204500);assert.equal(s.amount,1329250);
});
test('có thể cấu hình nhiều bao một lượt nhưng KHÔNG tính từ 50kg',()=>{
 const l=lot({bagsPerEntry:2,tareMode:'per_bag',tarePerBagGrams:500});
 const s=summarize(l,[mk(41000,2),mk(61000,2,'e2')]);
 assert.equal(s.count,2);assert.equal(s.bagsActual,4);assert.equal(s.tare,2000);assert.equal(s.net,100000);
});
test('dữ liệu cũ chế độ trừ cuối (0 bao) được hiểu 1 bao mỗi lượt',()=>{
 const l=lot({tareMode:'after'});
 const s=summarize(l,[mk(41000,0),mk(61000,0,'e2')]);
 assert.equal(s.count,2);assert.equal(s.bagsActual,2);assert.equal(s.net,102000);
 assert.match(csvForLot(l,[mk(41000,0)]),/TỔNG SỐ BAO THỰC TẾ/);
});
test('trừ bì cuối tính trên tổng khối lượng, tổng bao vẫn tính theo lượt',()=>{
 const l=lot({finalTareGrams:3500,tareMode:'after'});
 const s=summarize(l,[mk(500000),mk(300000,1,'e2')]);
 assert.equal(s.net,796500);assert.equal(s.bagsActual,2);assert.equal(s.count,2);
});
test('bì lớn hơn tổng cân bị từ chối',()=>{
 const l=lot({finalTareGrams:90000});assert.throws(()=>summarize(l,[mk(80000)]));
});
test('giữ số bao lịch sử khi cập nhật cấu hình lượt mới',()=>{
 const l=lot({bagsPerEntry:1,tareMode:'per_bag'});
 const s=summarize(l,[mk(125500,3),mk(80000,1,'e2')]);
 assert.equal(s.bagsActual,4);
});
test('không chấp nhận cấu hình 0 hoặc số âm bao/lượt',()=>{
 assert.throws(()=>validateLot(lot({bagsPerEntry:0})));
 assert.throws(()=>validateLot(lot({bagsPerEntry:-1})));
 assert.doesNotThrow(()=>validateLot(lot({bagsPerEntry:1})));
});
test('xuất CSV ghi rõ bao thực tế, không có quy đổi 50kg',()=>{
 const l=lot({finalTareGrams:1000});const v=csvForLot(l,[mk(100000)]);
 assert.match(v,/Số bao thực/);assert.match(v,/TỔNG SỐ BAO THỰC TẾ/);assert.match(v,/KG THỰC NHẬN/);
 assert.doesNotMatch(v,/bao quy đổi|Kg mỗi bao quy đổi|50 kg\/bao/i);
});
test('phiếu cân chỉ ghi bao thực tế',()=>{
 const text=receiptForLot(lot(),[mk(60000)]);
 assert.match(text,/Số bao thực tế: 1 bao/);assert.doesNotMatch(text,/quy đổi/i);
});
test('sao lưu PWA mới hợp lệ',()=>{
 const l=lot(),e={...mk(2500),lotId:l.id};
 assert.equal(checkedBackup({kind:'CAN_LUA_PWA_BACKUP',schema:1,lots:[l],entries:[e]}).entries.length,1);
});
test('phục hồi PWA 0.7.0 bổ sung cấu hình 1 bao/lượt, không mất dữ liệu cũ',()=>{
 const old=lot();delete old.bagsPerEntry;old.kgPerBagGrams=50000;
 const e={...mk(91000,3),lotId:old.id};
 const restored=checkedBackup({kind:'CAN_LUA_PWA_BACKUP',schema:1,lots:[old],entries:[e]});
 assert.equal(restored.lots[0].bagsPerEntry,1);
 assert.equal(restored.entries[0].bagCount,3);
 assert.equal(summarize(restored.lots[0],restored.entries).bagsActual,3);
 assert.equal(normalizeLot(old).bagsPerEntry,1);
});
test('sao lưu không chấp nhận lượt cân mồ côi',()=>{
 const l=lot();assert.throws(()=>checkedBackup({kind:'CAN_LUA_PWA_BACKUP',schema:1,lots:[l],entries:[mk(2500)]}));
});
test('tổng tiền chính xác số nguyên',()=>{
 const s=summarize(lot({priceVnd:6300}),[mk(10100)]);assert.equal(s.amount,63630);
});
test('dữ liệu kg chấp nhận 1, 2 số thập phân với dấu phẩy/chấm',()=>{
 assert.equal(fmtKg(125500),'125,5');assert.equal(gramsFromInput('15.25'),15250);
});

test('tiền lúa toàn lô được tính từ tổng kg trước bì',()=>{
 const l=lot({priceVnd:8200,tareMode:'after',finalTareGrams:12500});
 const s=summarize(l,[mk(625500),mk(620000,1,'e2')]);
 assert.equal(s.count,2);
 assert.equal(s.bagsActual,2);
 assert.equal(s.gross,1245500);
 assert.equal(s.grossAmount,10213100);
 assert.equal(s.net,1233000);
 assert.equal(s.amount,10110600);
});
test('chưa nhập giá không tự đưa ra tiền giả',()=>{
 const l=createLot('Nông dân A');
 assert.equal(l.priceVnd,0);
 assert.equal(summarize(l,[mk(51000)]).grossAmount,0);
});
test('bì là kg thỏa thuận sau khi cân chứ không mặc định tính tiền đầu bao',()=>{
 const l=lot({priceVnd:8000,tareMode:'after',finalTareGrams:0});
 const s=summarize(l,[mk(55000),mk(47000,1,'e2')]);
 assert.equal(s.tare,0);
 assert.equal(s.grossAmount,s.amount);
 assert.equal(s.bagsActual,2);
});
test('CSV tách giá trị lúa trước và sau bì',()=>{
 const l=lot({priceVnd:7500,finalTareGrams:500});
 const csv=csvForLot(l,[mk(45000)]);
 assert.match(csv,/TIỀN LÚA TRƯỚC BÌ/);
 assert.match(csv,/THANH TOÁN SAU BÌ/);
});

test('lượt cân nhanh trong cùng 1 mili giây vẫn giữ đúng thứ tự',()=>{
 const d='2026-10-10T01:00:00.000Z';
 const a={...mk(52000,1,'zz'),createdAt:d,sequence:1};
 const b={...mk(46000,1,'aa'),createdAt:d,sequence:2};
 assert.deepEqual(orderEntries([b,a]).map(x=>x.grossGrams),[52000,46000]);
 assert.doesNotThrow(()=>validateEntry(b));
});
