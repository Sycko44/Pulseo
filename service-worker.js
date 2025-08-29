// ✅ Bump des caches pour forcer la mise à jour côté navigateur
const PRECACHE = 'pulseo-precache-v4';
const RUNTIME  = 'pulseo-runtime-v4';

const PRECACHE_URLS = [
  './',
  'index.html','styles.css','app.js','i18n.js','db.js',
  'manifest.webmanifest','icon-192.png','icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(PRECACHE).then((cache) => cache.addAll(PRECACHE_URLS)).then(self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => ![PRECACHE, RUNTIME].includes(k)).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);
  if (req.method !== 'GET') return;

  // Stratégie cache-first pour assets statiques
  if (url.pathname.endsWith('.css') || url.pathname.endsWith('.js') ||
      url.pathname.endsWith('.png') || url.pathname.endsWith('.webmanifest')) {
    event.respondWith(
      caches.open(RUNTIME).then(async (cache) => {
        const cached = await cache.match(req);
        if (cached) return cached;
        const resp = await fetch(req);
        cache.put(req, resp.clone());
        return resp;
      })
    );
    return;
  }

  // Fallback offline vers index.html
  event.respondWith(fetch(req).catch(() => caches.match('index.html')));
});