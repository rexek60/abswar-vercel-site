const CACHE_NAME = 'centradar-static-v16';
const STATIC_ASSETS = [
  '/',
  '/og.png',
  '/socket.io.min.js',
  '/shoot.mp3',
  '/hit.mp3',
  '/purchase.mp3',
  '/eliminated.mp3',
  '/victory.mp3',
  '/error.mp3',
  '/assets/centradar-app-icon.svg',
  '/assets/centradar-emblem.png',
  '/assets/centradar-emblem-icon.png',
  '/assets/centradar-theme-background.jpg',
  '/assets/centradar-theme-og.jpg',
  '/assets/centradar-theme-emblem.png',
  '/assets/centradar-mission-start.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      await Promise.allSettled(
        STATIC_ASSETS.map(asset => cache.add(new Request(asset, { cache: 'reload' })))
      );
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);
  if (req.method !== 'GET' || url.pathname.startsWith('/api/') || url.pathname.startsWith('/socket.io/')) return;
  if (url.origin !== self.location.origin) return;
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then(async response => {
          if (response.ok) {
            const cache = await caches.open(CACHE_NAME);
            await cache.put('/', response.clone());
          }
          return response;
        })
        .catch(() => caches.match('/'))
    );
    return;
  }
  const fresh = fetch(req, { cache: 'no-cache' })
    .then(async response => {
      if (response.ok) {
        const cache = await caches.open(CACHE_NAME);
        await cache.put(req, response.clone());
      }
      return response;
    })
    .catch(() => null);
  event.waitUntil(fresh.then(() => undefined));
  event.respondWith(
    caches.match(req).then(cached => cached || fresh.then(response => response || Response.error()))
  );
});
