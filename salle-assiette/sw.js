// sw.js (Salle & Assiette) : ouverture instantanée et hors-ligne, mises à jour en douceur.
//
// - Installation : copie de l'appli (page, manifest, icônes). Elle s'ouvre donc sans réseau dès la 2e visite.
// - Page (index.html) : on affiche tout de suite la copie gardée (rapide, même en sous-sol de salle),
//   et en parallèle on télécharge la dernière version. Si elle a changé, on prévient la page,
//   qui propose « Nouvelle version · Mettre à jour ».
// - Polices Google et icônes : copie gardée d'abord, réseau sinon.
// - Le reste (API Claude, futur backend, autres sites) passe sans être touché.
// - Ne nettoie que les caches « salle-assiette-… » : jamais celui de l'appli à la racine du dépôt.
//
// Changer VERSION seulement si la liste SHELL change ou si ce fichier change de logique.

const VERSION = "v2.1";
const CACHE = "salle-assiette-" + VERSION;
const SHELL = [
  "./",
  "./manifest.json",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-maskable-512.png",
  "./icons/icon.svg",
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith("salle-assiette-") && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Télécharge la dernière page, la range sous « ./ » et prévient les onglets si elle a changé.
// La page qui s'ouvre n'existe pas encore pour le service worker au moment où la comparaison se termine :
// on attend qu'elle soit prête (5 s au plus) avant de la prévenir, ainsi que les autres onglets ouverts.
async function notify(clientId) {
  for (let i = 0; i < 20; i++) {
    const c = clientId ? await self.clients.get(clientId) : null;
    if (c || !clientId) break;
    await new Promise((r) => setTimeout(r, 250));
  }
  const tabs = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
  tabs.forEach((c) => c.postMessage({ type: "maj" }));
}

async function refreshPage(cache, oldText, clientId) {
  try {
    const res = await fetch("./", { cache: "no-cache" });
    if (!res.ok) return res;
    const fresh = await res.clone().text();
    const before = oldText ? await oldText : null;
    await cache.put("./", res.clone());
    if (before !== null && before !== fresh) await notify(clientId);
    return res;
  } catch (e) {
    return null;
  }
}

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  const scope = new URL(self.registration.scope);
  const ownFile = url.origin === scope.origin && url.pathname.startsWith(scope.pathname);
  const font = url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com";
  if (!ownFile && !font) return;

  // Page de l'appli : copie gardée tout de suite, mise à jour en arrière-plan.
  if (req.mode === "navigate") {
    event.respondWith(
      (async () => {
        const cache = await caches.open(CACHE);
        const old = await cache.match("./");
        // copie du texte AVANT d'envoyer « old » à l'écran (une réponse ne se lit qu'une fois)
        const update = refreshPage(cache, old ? old.clone().text() : null, event.resultingClientId);
        if (old) {
          event.waitUntil(update);
          return old;
        }
        return (await update) || new Response("Hors ligne", { status: 503, headers: { "Content-Type": "text/plain; charset=utf-8" } });
      })()
    );
    return;
  }

  // manifest.json : réseau d'abord (la page vérifie qu'il existe), copie sinon.
  if (url.pathname.endsWith("/manifest.json")) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          if (res.ok) caches.open(CACHE).then((c) => c.put("./manifest.json", res.clone()));
          return res;
        })
        .catch(() => caches.match("./manifest.json"))
    );
    return;
  }

  // Icônes, polices : copie d'abord, réseau sinon (et on garde ce qui arrive).
  event.respondWith(
    caches.match(req).then(
      (hit) =>
        hit ||
        fetch(req).then((res) => {
          if (res && (res.ok || res.type === "opaque")) {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put(req, copy));
          }
          return res;
        })
    )
  );
});
