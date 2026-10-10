const DB_NAME='can-lua-pro-pwa-v1';
export function openDb() {
  return new Promise((resolve,reject)=> {
    const req=indexedDB.open(DB_NAME,1);
    req.onupgradeneeded=()=> {
      const db=req.result;
      const lots=db.createObjectStore('lots',{keyPath:'id'});
      const entries=db.createObjectStore('entries',{keyPath:'id'});
      entries.createIndex('by_lot','lotId',{unique:false});
    };
    req.onerror=()=>reject(req.error);
    req.onsuccess=()=>resolve(req.result);
  });
}
export function all(db,store) {return new Promise((resolve,reject)=>{
  const t=db.transaction(store,'readonly'),req=t.objectStore(store).getAll();
  req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);
});}
export function write(db, store, value) {return new Promise((resolve,reject)=>{
  const t=db.transaction(store,'readwrite');t.objectStore(store).put(value);
  t.oncomplete=()=>resolve();t.onerror=()=>reject(t.error);t.onabort=()=>reject(t.error);
});}
export function remove(db,store,id) {return new Promise((resolve,reject)=>{
  const t=db.transaction(store,'readwrite');t.objectStore(store).delete(id);
  t.oncomplete=()=>resolve();t.onerror=()=>reject(t.error);t.onabort=()=>reject(t.error);
});}
export function replaceAll(db,lots,entries){return new Promise((resolve,reject)=>{
  const t=db.transaction(['lots','entries'],'readwrite');
  t.objectStore('lots').clear();t.objectStore('entries').clear();
  lots.forEach(x=>t.objectStore('lots').put(x));entries.forEach(x=>t.objectStore('entries').put(x));
  t.oncomplete=()=>resolve();t.onerror=()=>reject(t.error);t.onabort=()=>reject(t.error);
});}
export function deleteLot(db,id){return new Promise((resolve,reject)=>{
  const t=db.transaction(['lots','entries'],'readwrite');
  t.objectStore('lots').delete(id);
  const idx=t.objectStore('entries').index('by_lot');
  idx.openKeyCursor(IDBKeyRange.only(id)).onsuccess=e=>{
    const cursor=e.target.result;if(cursor){t.objectStore('entries').delete(cursor.primaryKey);cursor.continue();}
  };
  t.oncomplete=()=>resolve();t.onerror=()=>reject(t.error);t.onabort=()=>reject(t.error);
});}
