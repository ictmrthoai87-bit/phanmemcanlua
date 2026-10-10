const CACHE = 'can-lua-pro-0.7.2-r1';
const FILES = ['./','./index.html','./styles.css','./app.mjs','./model.mjs','./db.mjs','./manifest.webmanifest','./icons/icon-192.png','./icons/icon-512.png'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES)).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(Promise.all([
  caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('can-lua-pro-') && k!==CACHE).map(k=>caches.delete(k)))),
  self.clients.claim()
])));
self.addEventListener('fetch',e=>{
  const req=e.request;
  if(req.method!=='GET' || new URL(req.url).origin!==self.location.origin)return;
  e.respondWith((async()=>{
    const cache=await caches.open(CACHE);
    if(req.mode==='navigate'){
      try { const response=await fetch(req); if(response.ok) await cache.put('./index.html',response.clone()); return response; }
      catch { return (await cache.match('./index.html')) || Response.error(); }
    }
    const cached=await cache.match(req);if(cached)return cached;
    const response=await fetch(req);
    if(response.ok && new URL(req.url).pathname.startsWith(new URL(self.registration.scope).pathname)) await cache.put(req,response.clone());
    return response;
  })());
});
