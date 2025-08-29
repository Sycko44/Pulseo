const PRECACHE='pulseo-precache-v1'; const RUNTIME='pulseo-runtime-v1';
const PRECACHE_URLS=['./','index.html','styles.css','app.js','i18n.js','db.js','manifest.webmanifest','icon-192.png','icon-512.png'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(PRECACHE).then(c=>c.addAll(PRECACHE_URLS)).then(self.skipWaiting()))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>![PRECACHE,RUNTIME].includes(k)).map(k=>caches.delete(k)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{const req=e.request; const url=new URL(req.url); if(req.method!=='GET') return;
 if(url.pathname.endsWith('.css')||url.pathname.endsWith('.js')||url.pathname.endsWith('.png')||url.pathname.endsWith('.webmanifest')){
  e.respondWith(caches.open(RUNTIME).then(async cache=>{const cached=await cache.match(req); if(cached) return cached; const resp=await fetch(req); cache.put(req, resp.clone()); return resp;})); return;}
 e.respondWith(fetch(req).catch(()=>caches.match('index.html')));
});
self.addEventListener('push',e=>{const data=(e.data&&e.data.text())||'Pulseo — notification'; e.waitUntil(self.registration.showNotification('Pulseo',{body:data,icon:'icon-192.png'}));});
self.addEventListener('sync',e=>{ if(e.tag==='sync-messages'){ e.waitUntil(Promise.resolve()); }});
