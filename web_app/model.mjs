// Can Lua Pro - calculations use integer grams, never fractional floating kg storage.
export const VERSION = '0.7.2';
export const MONEY = new Intl.NumberFormat('vi-VN', {maximumFractionDigits: 0});
export const KG = new Intl.NumberFormat('vi-VN', {minimumFractionDigits: 0, maximumFractionDigits: 2});
export const makeId = () => globalThis.crypto?.randomUUID?.() ?? `lot-${Date.now()}-${Math.floor(Math.random()*1e9)}`;

export function gramsFromInput(value, maxDecimals=2, {allowZero=false}={}) {
  const v = String(value ?? '').trim();
  const re = maxDecimals === 1 ? /^(\d{1,8})(?:[.,](\d{1}))?$/ : /^(\d{1,8})(?:[.,](\d{1,2}))?$/;
  const m = re.exec(v);
  if (!m) throw new Error(`Nhập số kg hợp lệ (tối đa ${maxDecimals} chữ số lẻ), ví dụ: 125,5.`);
  const grams = Number(m[1]) * 1000 + Number((m[2] || '').padEnd(3, '0'));
  if (!Number.isSafeInteger(grams) || grams > 1000000000 || (grams === 0 && !allowZero)) {
    throw new Error('Số kg không hợp lệ hoặc vượt giới hạn 1.000.000 kg.');
  }
  return grams;
}
export function gramsFromBackup(value) {
  if (!Number.isSafeInteger(value) || value < 0 || value > 1000000000) throw new Error('Số gram trong sao lưu không hợp lệ.');
  return value;
}
export function safeWhole(value, label, max=10000000) {
  const n = Number(value);
  if (String(value).trim()==='' || !Number.isSafeInteger(n) || n<0 || n>max) throw new Error(`${label} phải là số nguyên từ 0 đến ${MONEY.format(max)}.`);
  return n;
}
export function fmtKg(grams) { return KG.format(grams / 1000); }
export function fmtMoney(value) { return MONEY.format(value) + ' đ'; }
export function createLot(name, now=new Date()) {
  return { id:makeId(), name:name.trim() || 'Lô lúa mới', customer:'', rice:'', priceVnd:0,
    decimals:2, tareMode:'after', tarePerBagGrams:500, finalTareGrams:0,
    bagsPerEntry:1, paidVnd:0, createdAt:now.toISOString(), updatedAt:now.toISOString() };
}
// Old V0.7.0 lots did not include bagsPerEntry; keep all existing entries unchanged.
export function normalizeLot(lot) {
  return {...lot, bagsPerEntry: lot.bagsPerEntry == null ? 1 : lot.bagsPerEntry};
}
// V0.7.0 saved bagCount=0 for every "tare at end" entry.
// Treat those legacy zeros as one actual bag, without overwriting the original record.
export function actualBagsForEntry(entry, lot) {
  return lot.tareMode==='after' && entry.bagCount===0 ? 1 : entry.bagCount;
}
// Preserves order when rapid entries share the same millisecond timestamp.
// Legacy backups without `sequence` remain in timestamp order.
export function orderEntries(items) {
  return [...items].sort((a,b) => {
    const nA=Number.isSafeInteger(a.sequence)?a.sequence:0;
    const nB=Number.isSafeInteger(b.sequence)?b.sequence:0;
    return nA-nB || a.createdAt.localeCompare(b.createdAt) || a.id.localeCompare(b.id);
  });
}
export function entryNetGrams(entry, lot) {
  return lot.tareMode === 'per_bag' ? entry.grossGrams - entry.bagCount*lot.tarePerBagGrams : entry.grossGrams;
}
export function summarize(lot, entries) {
  const gross = entries.reduce((s,e)=>s+e.grossGrams,0);
  const bagsActual = entries.reduce((s,e)=>s+actualBagsForEntry(e,lot),0);
  const tare = lot.tareMode==='per_bag' ? bagsActual * lot.tarePerBagGrams : lot.finalTareGrams;
  const net = gross - tare;
  if (net < 0 || !Number.isSafeInteger(net)) throw new Error('Tổng bì lớn hơn tổng cân hoặc vượt giới hạn.');
  if (lot.tareMode === 'per_bag' && entries.some(e=>entryNetGrams(e,lot)<0)) throw new Error('Một lượt cân có bì lớn hơn số kg cân.');
  // Show gross rice value prominently until farmers and traders agree on tare.
  const grossAmount = Math.round(gross * lot.priceVnd / 1000);
  const amount = Math.round(net * lot.priceVnd / 1000);
  const balance = amount - lot.paidVnd;
  if (![grossAmount,amount,balance].every(Number.isSafeInteger)) throw new Error('Giá trị tính tiền vượt giới hạn.');
  return {gross, bagsActual, tare, net, grossAmount, amount, balance, count:entries.length};
}
export function validateLot(lot) {
  if (!lot || typeof lot !== 'object' || !String(lot.name||'').trim() || String(lot.name).length > 120) throw new Error('Tên lô không hợp lệ.');
  if (!['per_bag','after'].includes(lot.tareMode)) throw new Error('Phương pháp trừ bì không hợp lệ.');
  if (![1,2].includes(lot.decimals)) throw new Error('Số lẻ phải bằng 1 hoặc 2.');
  for (const [key, max] of [['priceVnd',10000000],['paidVnd',1000000000000],['tarePerBagGrams',1000000000],['finalTareGrams',1000000000]]) {
    if (!Number.isSafeInteger(lot[key]) || lot[key]<0 || lot[key]>max) throw new Error(`Trường ${key} không hợp lệ.`);
  }
  if (!Number.isSafeInteger(lot.bagsPerEntry ?? 1) || (lot.bagsPerEntry ?? 1) < 1 || (lot.bagsPerEntry ?? 1) > 1000)
    throw new Error('Số bao mỗi lượt cân phải từ 1 đến 1.000.');
  // Preserve old backup compatibility without using the retired 50 kg/bag conversion.
  if (lot.kgPerBagGrams !== undefined && (!Number.isSafeInteger(lot.kgPerBagGrams) || lot.kgPerBagGrams < 1000 || lot.kgPerBagGrams > 1000000))
    throw new Error('Dữ liệu quy đổi của bản cũ không hợp lệ.');
  for (const s of ['customer','rice']) if (typeof lot[s] !== 'string' || lot[s].length>150) throw new Error('Thông tin lô không hợp lệ.');
}
export function validateEntry(entry) {
  if (!entry || typeof entry.id!=='string' || typeof entry.lotId!=='string' || !entry.id || !entry.lotId) throw new Error('Mã lượt cân không hợp lệ.');
  gramsFromBackup(entry.grossGrams);
  if (entry.sequence !== undefined && (!Number.isSafeInteger(entry.sequence) || entry.sequence < 1 || entry.sequence > 1000000000)) throw new Error('Thứ tự lượt cân không hợp lệ.');
  if (entry.grossGrams<=0) throw new Error('Số cân phải lớn hơn 0.');
  if (!Number.isSafeInteger(entry.bagCount) || entry.bagCount<0 || entry.bagCount>1000000) throw new Error('Số bao không hợp lệ.');
  if (typeof entry.note!=='string' || entry.note.length>500) throw new Error('Ghi chú không hợp lệ.');
}
const csvCell = x => {
  const s=String(x??'');
  const safe=/^[=+@\-\t\r]/.test(s) ? ` '${s}` : s; // prevent Excel formula injection
  return `"${safe.replaceAll('\"','\"\"')}"`;
};
export function csvForLot(lot, entries) {
  const sum=summarize(lot,entries);
  const rows=[
    ['CÂN LÚA PRO',VERSION],['Tên lô',lot.name],['Người bán',lot.customer],['Giống lúa',lot.rice],
    ['Chế độ bì',lot.tareMode==='per_bag'?'Theo đầu bao':'Trừ cuối'],['Giá/kg (đ)',lot.priceVnd],
    ['Bao mỗi lượt cân (cấu hình)',lot.bagsPerEntry ?? 1],[],
    ['STT','Ngày giờ','Số cân (kg)','Số bao thực','Bì lượt (kg)','Kg sau trừ bì lượt (kg)','Ghi chú']
  ];
  entries.forEach((e,i)=> {
    const tare = lot.tareMode==='per_bag' ? e.bagCount*lot.tarePerBagGrams : 0;
    const net = e.grossGrams-tare;
    rows.push([i+1,new Date(e.createdAt).toLocaleString('vi-VN'),fmtKg(e.grossGrams),actualBagsForEntry(e,lot),
      lot.tareMode==='per_bag'?fmtKg(tare):'Trừ cuối',fmtKg(net),e.note]);
  });
  rows.push([],['TỔNG KG CÂN',fmtKg(sum.gross)],['TỔNG BÌ (kg)',fmtKg(sum.tare)],
    ['KG THỰC NHẬN',fmtKg(sum.net)],['TỔNG SỐ BAO THỰC TẾ',sum.bagsActual],['TỔNG LƯỢT CÂN',sum.count],
    ['TIỀN LÚA TRƯỚC BÌ (đ)',sum.grossAmount],['THANH TOÁN SAU BÌ (đ)',sum.amount],['ĐÃ TRẢ (đ)',lot.paidVnd],['CÒN PHẢI TRẢ (đ)',sum.balance]);
  if (lot.tareMode==='after') rows.push(['Ghi chú','Tổng bì chỉ được trừ một lần ở cuối lô; kg theo lượt là trước trừ bì cuối.']);
  return '\uFEFF'+rows.map(row=>row.map(csvCell).join(';')).join('\r\n');
}
export function receiptForLot(lot,entries) {
  const s=summarize(lot,entries);
  return [
    'CÂN LÚA PRO - PHIẾU CÂN',`Phiên bản ${VERSION} • Edit: Lê Ngọc Thoại`,
    `Lô: ${lot.name}`,`Người bán: ${lot.customer || '—'}`,`Giống lúa: ${lot.rice || '—'}`,
    `Số lượt cân: ${s.count}`,`Tổng cân: ${fmtKg(s.gross)} kg`,
    `Trừ bì: ${fmtKg(s.tare)} kg (${lot.tareMode==='per_bag'?'Theo đầu bao':'Trừ cuối'})`,
    `Kg thực: ${fmtKg(s.net)} kg`, `Số bao thực tế: ${s.bagsActual} bao`,
    `Đơn giá: ${lot.priceVnd ? fmtMoney(lot.priceVnd)+'/kg' : 'Chưa cài'}`, `Tiền lúa trước bì: ${lot.priceVnd ? fmtMoney(s.grossAmount) : 'Chưa nhập đơn giá'}`, `Tiền sau bì: ${lot.priceVnd ? fmtMoney(s.amount) : 'Chưa nhập đơn giá'}`, `Đã trả: ${fmtMoney(lot.paidVnd)}`,
    `Còn lại: ${fmtMoney(s.balance)}`,'—',
    ...entries.map((e,i)=>`${i+1}. ${fmtKg(e.grossGrams)} kg • ${actualBagsForEntry(e,lot)} bao • ${new Date(e.createdAt).toLocaleString('vi-VN')}`)
  ].join('\n');
}
export function checkedBackup(data) {
  if (!data || data.kind!=='CAN_LUA_PWA_BACKUP' || data.schema!==1 || !Array.isArray(data.lots) || !Array.isArray(data.entries)) throw new Error('Tệp sao lưu không đúng định dạng CÂN LÚA PRO PWA.');
  if (data.lots.length>10000 || data.entries.length>200000) throw new Error('Tệp sao lưu vượt giới hạn.');
  const lotIds=new Set(), entryIds=new Set();
  for (const lot of data.lots) {
    if (typeof lot.id!=='string' || !lot.id || lot.id.length>100 || lotIds.has(lot.id)) throw new Error('Mã lô bị trùng hoặc không hợp lệ.');
    validateLot(lot);
    if (!Number.isFinite(Date.parse(lot.createdAt)) || !Number.isFinite(Date.parse(lot.updatedAt))) throw new Error('Ngày tạo/cập nhật lô không hợp lệ.');
    lotIds.add(lot.id);
  }
  for (const entry of data.entries) {
    validateEntry(entry);
    if (!Number.isFinite(Date.parse(entry.createdAt))) throw new Error('Ngày của lượt cân không hợp lệ.');
    if (!lotIds.has(entry.lotId) || entryIds.has(entry.id)) throw new Error('Lượt cân không liên kết đúng lô hoặc bị trùng.');
    entryIds.add(entry.id);
  }
  for (const lot of data.lots) summarize(lot,data.entries.filter(e=>e.lotId===lot.id));
  return {lots:data.lots.map(normalizeLot),entries:data.entries};
}
