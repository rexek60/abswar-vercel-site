const CACHE_NAME = 'centradar-static-v6';
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
  '/assets/centradar-mission-start.png',
  '/assets/centradar-mission-live-bg.jpg',
  '/assets/centradar-war-background.mp3'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS))
      .catch(() => undefined)
  );
  self.skipWaiting();
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
  if (req.mode === 'navigate') {
    event.respondWith(fetch(req).catch(() => caches.match('/')));
    return;
  }
  event.respondWith(caches.match(req).then(cached => cached || fetch(req)));
});
