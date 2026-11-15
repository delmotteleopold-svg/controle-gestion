// sw.js : permet à l'appli de s'ouvrir sans internet.
// Quand il y a du réseau, on charge la dernière version (et on la garde en copie).
// Sans réseau, on ouvre la dernière copie gardée.

const CACHE = "ma-vie-v1";

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(["./", "./index.html"])));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;
  const url = new URL(request.url);
  const ownFile = url.origin === self.location.origin;
  const font = url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com";
  if (!ownFile && !font) return; // Google Agenda et le reste passent sans toucher

  event.respondWith(
    fetch(request)
      .then((response) => {
        if (response && (response.ok || response.type === "opaque")) {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put(request, copy));
        }
        return response;
      })
      .catch(() =>
        caches.match(request).then((hit) => {
          if (hit) return hit;
          if (request.mode === "navigate") return caches.match("./index.html").then((page) => page || caches.match("./"));
          return undefined;
        })
      )
  );
});
