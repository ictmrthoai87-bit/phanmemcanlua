import {VERSION, makeId, createLot, normalizeLot, fmtKg, fmtMoney, gramsFromInput, safeWhole, summarize, entryNetGrams, actualBagsForEntry, validateLot, csvForLot, receiptForLot, checkedBackup, orderEntries} from './model.mjs';
import {openDb, all, write, remove, replaceAll, deleteLot} from './db.mjs';
const $=id=>document.getElementById(id);
const esc=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const state={db:null,lots:[],entries:[],lotId:null,tab:'can',saving:false,editId:null};
let toastTimer;
function toast(message) {
  const el=$('toast');el.textContent=message;el.classList.add('visible');
  clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.classList.remove('visible'),2400);
}
function fail(err){ console.error(err);toast(err?.message||'Có lỗi xảy ra. Vui lòng thử lại.'); }
function lot(){return state.lots.find(l=>l.id===state.lotId);}
function entries(){return orderEntries(state.entries.filter(e=>e.lotId===state.lotId));}
const localDate = () => new Date().toLocaleDateString('vi-VN');
function selectTab(tab){
  if(tab!=='can' && document.activeElement===$('weight-input')) $('weight-input').blur();
  state.tab=tab;
  document.querySelectorAll('[data-tab]').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab));
  document.querySelectorAll('.tabpage').forEach(page=>page.classList.toggle('hidden',page.id!==`page-${tab}`));
  if(tab==='cau-hinh') renderSettings(); adjustKeyboard();
  window.scrollTo({top:0,behavior:'instant'});
}
async function sync({settings=false}={}) {
  [state.lots,state.entries]=await Promise.all([all(state.db,'lots'),all(state.db,'entries')]);
  state.lots=state.lots.map(normalizeLot);
  state.lots.sort((a,b)=>b.createdAt.localeCompare(a.createdAt));
  if(!state.lots.length) { const init=createLot(`Lô lúa ${localDate()}`);await write(state.db,'lots',init);state.lots=[init]; }
  if(!state.lots.some(x=>x.id===state.lotId))state.lotId=state.lots[0].id;
  localStorage.setItem('can_lua_current_lot',state.lotId);
  const picker=$('lot-picker');
  picker.replaceChildren(...state.lots.map(item=>{
    const option=document.createElement('option');option.value=item.id;option.textContent=item.name;return option;
  }));
  picker.value=state.lotId;
  renderData();if(settings || state.tab==='cau-hinh')renderSettings();
}
function oneRow(entry,index,l,{controls=false}={}){
  const date=new Date(entry.createdAt).toLocaleString('vi-VN', {day:'2-digit',month:'2-digit',hour:'2-digit',minute:'2-digit'});
  return `<div class="entry-row"><div><div class="title">Bao ${index+1} <span class="entry-weight">${fmtKg(entry.grossGrams)} kg</span></div><small>${esc(date)}${entry.note?' • '+esc(entry.note):''}</small></div>${controls?`<div class="row-buttons"><button type="button" data-edit="${esc(entry.id)}" aria-label="Sửa bao ${index+1}">Sửa</button><button type="button" data-delete="${esc(entry.id)}" aria-label="Xóa bao ${index+1}">Xóa</button></div>`:''}</div>`;
}
function renderData(){
 const l=lot();if(!l)return;
 const e=entries(),s=summarize(l,e);
 const latest=e[e.length-1], prior=e[e.length-2];
 $('last-weight').textContent=latest?`${fmtKg(latest.grossGrams)} kg`:'—'; $('edit-last').hidden=!latest; $('edit-last').dataset.id=latest?.id||'';
 $('prior-weight').textContent=prior?`${fmtKg(prior.grossGrams)} kg`:'—';
 $('live-gross').textContent=fmtKg(s.gross);
 $('live-bag-count').textContent=String(s.bagsActual);
 $('live-money').textContent=l.priceVnd?fmtMoney(s.grossAmount):'Chưa nhập đơn giá';
 $('home-count').textContent=`${s.count} lượt • ${s.bagsActual} bao`;
 $('home-gross').textContent=`${fmtKg(s.gross)} kg`;
 $('home-price').textContent=l.priceVnd?`${fmtMoney(l.priceVnd)}/kg`:'Chưa đặt';
 $('home-amount').textContent=l.priceVnd?fmtMoney(s.grossAmount):'Chưa đặt giá';
 $('settlement-preview').hidden=!s.tare && !l.paidVnd;
 $('home-settled').textContent=l.priceVnd?fmtMoney(s.amount):'Chưa đặt giá';
 const newest=e.map((row,index)=>({row,index})).reverse();
 $('recent-list').innerHTML=newest.length?newest.slice(0,4).map(x=>oneRow(x.row,x.index,l)).join(''):'<p class="empty">Chưa có bao nào. Nhập kg rồi nhấn LƯU.</p>';
 $('entry-count-badge').textContent=`${s.count} lượt • ${s.bagsActual} bao`;
 $('full-list').innerHTML=newest.length?newest.map(x=>oneRow(x.row,x.index,l,{controls:true})).join(''):'<p class="empty">Chưa có lượt cân nào.</p>';
 const stats=[['Số lượt đã cân',String(s.count)],['Tổng số bao',String(s.bagsActual)+' bao'],['Tổng khối lượng',`${fmtKg(s.gross)} kg`],
  ['Đơn giá',l.priceVnd?fmtMoney(l.priceVnd)+'/kg':'Chưa nhập'],
  ['TIỀN LÚA TRƯỚC BÌ',l.priceVnd?fmtMoney(s.grossAmount):'Chưa nhập đơn giá'],
  ['Bì theo thỏa thuận',`${fmtKg(s.tare)} kg`],['Khối lượng thanh toán',`${fmtKg(s.net)} kg`],
  ['Thanh toán sau bì',l.priceVnd?fmtMoney(s.amount):'Chưa nhập đơn giá'],
  ['Đã trả',fmtMoney(l.paidVnd)],['Còn phải trả',l.priceVnd?fmtMoney(s.balance):'Chưa nhập đơn giá']];
 const note=s.tare===0?'<p class="muted">Chưa trừ bì. Khi nông dân và thương lái thống nhất, vào Cấu hình để nhập số kg bì (nếu có).</p>':'<p class="muted warning">Đã trừ bì theo thỏa thuận. Tiền lúa trước bì và tiền thanh toán sau bì được trình bày riêng.</p>';
 $('report-body').innerHTML=`<p><strong>${esc(l.name)}</strong></p><div class="report-stats">${stats.map(([a,b],i)=>`<div${i===4?' class="wide"':''}><label>${esc(a)}</label><strong>${esc(b)}</strong></div>`).join('')}</div>${note}`;
}
function renderSettings(){
 const l=lot();if(!l)return;
 $('lot-name').value=l.name;$('customer').value=l.customer;$('rice').value=l.rice;
 $('price').value=l.priceVnd;$('decimals').value=l.decimals;
 $('tare-mode').value=l.tareMode;$('tare-mode').disabled=entries().length>0;
 $('tare-per-bag').value=fmtKg(l.tarePerBagGrams);$('final-tare').value=fmtKg(l.finalTareGrams);
 $('bags-per-entry').value=l.bagsPerEntry ?? 1;$('paid').value=l.paidVnd;
 $('tare-lock-hint').textContent=entries().length ? 'Đã có lượt cân: không đổi chế độ trừ bì để tránh làm sai giao dịch.' : 'Có thể chọn trừ bì theo số bao hoặc trừ cuối.';
 toggleTareFields();
}
function toggleTareFields(){const mode=$('tare-mode').value;$('per-bag-settings').hidden=mode!=='per_bag';$('final-tare-settings').hidden=mode!=='after';}
async function saveEntry(ev){
 ev.preventDefault();
 if(state.saving)return;
 const input=$('weight-input');
 const inputSnapshot=input.value;
 // Focus synchronously within the tap/keyboard event. Do not blur after saving:
 // iOS Safari cannot reliably re-open the software keyboard after an await.
 input.focus({preventScroll:true});
 const l=lot();let grams;
 try{
   grams=gramsFromInput(inputSnapshot,l.decimals);
   if(l.tareMode==='per_bag' && grams <= l.bagsPerEntry*l.tarePerBagGrams)
     throw new Error('Kg cân phải lớn hơn trọng lượng bì lượt này.');
 }catch(err){fail(err);return;}
 state.saving=true;$('save-entry').disabled=true;$('save-entry').setAttribute('aria-busy','true');$('save-label').textContent='ĐANG LƯU...';
 try {
   const noteSnapshot=$('note-input').value.trim();
   if(noteSnapshot.length>500)throw new Error('Ghi chú quá dài.');
   const nextSequence=Math.max(0,...entries().map(e=>e.sequence||0))+1;
   const entry={id:makeId(),lotId:l.id,grossGrams:grams,bagCount:l.bagsPerEntry,sequence:nextSequence,note:noteSnapshot,createdAt:new Date().toISOString()};
   await write(state.db,'entries',entry);
   // If the operator started typing the next bag while saving, NEVER erase that value.
   if(input.value===inputSnapshot)input.value='';
   if($('note-input').value.trim()===noteSnapshot)$('note-input').value='';
   await sync();
   if(navigator.vibrate)navigator.vibrate(25);
   const updated=summarize(lot(),entries()); toast(`✓ Đã lưu bao ${updated.count} • ${fmtKg(grams)} kg`); $('entry-status').textContent=`Đã lưu bao ${updated.count}: ${fmtKg(grams)} kg. Tiếp tục nhập bao sau.`;
 }catch(err){fail(err)}finally{
   state.saving=false;$('save-entry').disabled=false;$('save-entry').removeAttribute('aria-busy');$('save-label').textContent='✓ LƯU LƯỢT CÂN';
   // Intentionally do not call blur(), scrollTo(), or focus() after awaits.
 }
}
async function saveSettings(ev){
 ev.preventDefault();const old=lot(),e=entries();
 try{
 const next={...old,name:$('lot-name').value.trim(),customer:$('customer').value.trim(),rice:$('rice').value.trim(),
  priceVnd:safeWhole($('price').value,'Đơn giá',10000000),decimals:Number($('decimals').value),
  tareMode:$('tare-mode').value,tarePerBagGrams:gramsFromInput($('tare-per-bag').value,2,{allowZero:true}),
  finalTareGrams:gramsFromInput($('final-tare').value,2,{allowZero:true}),
  bagsPerEntry:safeWhole($('bags-per-entry').value,'Số bao mỗi lượt',1000), paidVnd:safeWhole($('paid').value,'Đã trả',1000000000000),updatedAt:new Date().toISOString()};
 if(e.length && next.tareMode!==old.tareMode)throw new Error('Lô đã có lượt cân, không được đổi phương pháp trừ bì.');
 validateLot(next);summarize(next,e);
 if(e.length && ((old.tareMode==='per_bag' && next.tarePerBagGrams!==old.tarePerBagGrams) || (old.tareMode==='after' && next.finalTareGrams!==old.finalTareGrams))) {
    if(!confirm('Đổi mức bì sẽ tính lại KG THỰC và TIỀN cho toàn bộ lượt cân trong lô. Bạn có đồng ý không?'))return;
 }
 await write(state.db,'lots',next);await sync({settings:true});toast('✓ Đã lưu cấu hình lô cân.');selectTab('can');
 }catch(err){fail(err)}
}
async function createNewLot(ev){
 ev.preventDefault();const name=$('new-lot-name').value.trim();if(!name){toast('Vui lòng nhập tên lô.');return;}
 try{const item=createLot(name);await write(state.db,'lots',item);state.lotId=item.id;$('lot-dialog').close();$('new-lot-name').value='';await sync({settings:true});selectTab('can');toast('✓ Đã tạo lô cân mới.');}
 catch(err){fail(err)}
}
function openEdit(id){const entry=state.entries.find(x=>x.id===id&&x.lotId===state.lotId);if(!entry)return;
 state.editId=id;$('edit-weight').value=fmtKg(entry.grossGrams);$('edit-note').value=entry.note;$('edit-dialog').showModal();
}
async function saveEdit(ev){
 ev.preventDefault();const entry=state.entries.find(x=>x.id===state.editId&&x.lotId===state.lotId),l=lot();if(!entry)return;
 try{
 const next={...entry,grossGrams:gramsFromInput($('edit-weight').value,l.decimals),note:$('edit-note').value.trim()};
 if(next.grossGrams<=next.bagCount*l.tarePerBagGrams && l.tareMode==='per_bag')throw new Error('Bì không được bằng hoặc lớn hơn số cân.');
 summarize(l,entries().map(x=>x.id===next.id?next:x));
 await write(state.db,'entries',next);$('edit-dialog').close();await sync();toast('✓ Đã sửa lượt cân.');
 }catch(err){fail(err)}
}
async function removeEntry(id){const entry=state.entries.find(x=>x.id===id && x.lotId===state.lotId);if(!entry || !confirm(`Xóa lượt cân ${fmtKg(entry.grossGrams)} kg? Không thể hoàn tác.`))return;
 try{summarize(lot(),entries().filter(x=>x.id!==id));await remove(state.db,'entries',id);await sync();toast('Đã xóa lượt cân.')}catch(err){fail(err)}
}
async function removeCurrentLot(){if(state.lots.length<=1){toast('Hãy tạo lô khác trước khi xóa lô này.');return;}
 const l=lot();if(!confirm(`Xóa vĩnh viễn lô "${l.name}" và TẤT CẢ lượt cân của lô? Hãy sao lưu trước.`))return;
 try{await deleteLot(state.db,l.id);state.lotId=null;await sync({settings:true});selectTab('can');toast('Đã xóa lô.');}catch(err){fail(err)}
}
function downloadFile(content,filename,type){const blob=new Blob([content],{type});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=filename;document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),30000);}
function downloadCsv(){try{downloadFile(csvForLot(lot(),entries()),`CanLua_${new Date().toISOString().slice(0,10)}.csv`,'text/csv;charset=utf-8');toast('Đã tạo báo cáo CSV.');}catch(err){fail(err)}}
async function backup(){
 try{const lots=await all(state.db,'lots'),rows=await all(state.db,'entries');
 const data={kind:'CAN_LUA_PWA_BACKUP',schema:1,appVersion:VERSION,createdAt:new Date().toISOString(),lots,entries:rows};
 downloadFile(JSON.stringify(data,null,2),`CAN_LUA_BACKUP_${new Date().toISOString().slice(0,10)}.json`,'application/json');toast('✓ Đã tạo tệp sao lưu. Hãy lưu nơi an toàn.');
 }catch(err){fail(err)}
}
async function restore(ev){
 const file=ev.target.files?.[0];if(!file)return;
 try{
 if(file.size>10*1024*1024)throw new Error('Tệp quá lớn, giới hạn 10 MB.');
 const data=checkedBackup(JSON.parse(await file.text()));
 if(!confirm(`Khôi phục ${data.lots.length} lô, ${data.entries.length} lượt cân? Dữ liệu hiện tại sẽ bị THAY THẾ. Bạn nên sao lưu trước.`))return;
 await replaceAll(state.db,data.lots,data.entries);state.lotId=data.lots[0]?.id||null;await sync({settings:true});selectTab('can');toast('✓ Khôi phục thành công.');
 }catch(err){fail(err)}finally{$('restore-file').value='';}
}
async function shareReceipt(){const text=receiptForLot(lot(),entries());
 try{if(navigator.share)await navigator.share({title:`Phiếu cân ${lot().name}`,text});
 else if(navigator.clipboard?.writeText){await navigator.clipboard.writeText(text);toast('Đã chép phiếu cân, có thể dán vào Zalo.');}
 else {downloadFile(text, 'PHIEU_CAN_LUA.txt','text/plain;charset=utf-8');toast('Đã tạo tệp phiếu cân.');}
 }catch(err){if(err?.name!=='AbortError')fail(err)}
}
function adjustKeyboard(){
 const vp=window.visualViewport;
 const overlap=vp?Math.max(0,window.innerHeight-(vp.height+vp.offsetTop)):0;
 const active=document.activeElement===$('weight-input') && matchMedia('(max-width: 700px)').matches;
 // Some Android browsers resize the layout viewport instead of visualViewport.
 // Focus-driven compact mode keeps last two bags and totals visible in both cases.
 document.body.classList.toggle('weigh-active',active);
 document.documentElement.style.setProperty('--keyboard-gap',`${overlap>130?Math.round(overlap):0}px`);
}

function bind(){
 document.querySelectorAll('[data-tab]').forEach(b=>b.addEventListener('click',()=>selectTab(b.dataset.tab)));
 document.querySelectorAll('[data-goto]').forEach(b=>b.addEventListener('click',()=>selectTab(b.dataset.goto)));
 $('quick-config').addEventListener('click',()=>selectTab('cau-hinh'));
 if(window.visualViewport){visualViewport.addEventListener('resize',adjustKeyboard);visualViewport.addEventListener('scroll',adjustKeyboard);} $('weight-input').addEventListener('focus',adjustKeyboard);$('weight-input').addEventListener('blur',()=>setTimeout(adjustKeyboard,0));$('exit-fast').addEventListener('click',()=>{$('weight-input').blur();adjustKeyboard();});
 $('lot-picker').addEventListener('change',async ev=>{state.lotId=ev.target.value;await sync({settings:true})});
 $('add-lot').addEventListener('click',()=>{$('new-lot-name').value='';$('lot-dialog').showModal();});
 $('cancel-lot').addEventListener('click',()=>$('lot-dialog').close());
 $('lot-form').addEventListener('submit',createNewLot);
 $('weight-form').addEventListener('submit',saveEntry);
 // Keep input focus/keyboard visible when save is tapped (supported browsers).
 $('save-entry').addEventListener('pointerdown', event=>{
   if(document.activeElement===$('weight-input'))event.preventDefault();
 });
 $('edit-last').addEventListener('click',()=>{ if($('edit-last').dataset.id) openEdit($('edit-last').dataset.id); });
 $('tare-mode').addEventListener('change',toggleTareFields);
 $('settings-form').addEventListener('submit',saveSettings);
 $('full-list').addEventListener('click',event=>{const b=event.target.closest('button');if(!b)return;if(b.dataset.edit)openEdit(b.dataset.edit);if(b.dataset.delete)removeEntry(b.dataset.delete)});
 $('cancel-edit').addEventListener('click',()=>$('edit-dialog').close());$('edit-form').addEventListener('submit',saveEdit);
 $('export-csv').addEventListener('click',downloadCsv);$('share-report').addEventListener('click',shareReceipt);
 $('backup-json').addEventListener('click',backup);$('restore-json').addEventListener('click',()=>$('restore-file').click());
 $('restore-file').addEventListener('change',restore);$('delete-lot').addEventListener('click',removeCurrentLot);
}
async function init(){try{
 state.db=await openDb();state.lotId=localStorage.getItem('can_lua_current_lot');bind();await sync({settings:true});
 adjustKeyboard(); if('serviceWorker' in navigator && location.protocol.startsWith('http')) navigator.serviceWorker.register('./sw.js').catch(console.warn);
 if(navigator.storage?.persist)navigator.storage.persist().catch(()=>{});
 }catch(err){fail(err);$('recent-list').textContent='Không mở được nơi lưu dữ liệu. Hãy sử dụng Safari/Chrome ở chế độ thường (không riêng tư), kiểm tra dung lượng và thử tải lại.';}
}
init();
