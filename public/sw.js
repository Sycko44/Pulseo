self.addEventListener("install", e=>{ e.waitUntil(caches.open("pulseo-v1").then(c=>c.addAll(["/","/dev/dashboard","/dev/simulate"]))); });
self.addEventListener("fetch", e=>{
  e.respondWith(caches.match(e.request).then(r=> r || fetch(e.request).then(resp=>{
    const clone = resp.clone(); caches.open("pulseo-v1").then(c=>c.put(e.request, clone)); return resp;
  })));
});
