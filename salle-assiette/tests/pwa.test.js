// Tests PWA de Salle & Assiette (Chromium : Android et iPhone simulés). Lancer : node salle-assiette/tests/pwa.test.js
// Le mini-serveur démarre et s'arrête avec le script. Prérequis : npm i -D playwright (puis npx playwright install chromium).
const { chromium, devices } = require('playwright');
const SP = require('os').tmpdir(); // captures d'écran
const URL_ = "http://localhost:8765/salle-assiette/";
(async () => {
  const srv = await require('./serve.js')(require('path').resolve(__dirname, '../..'), 8765);
  const b = await chromium.launch();
  const errs = [];
  try {
    const ctx = await b.newContext({ ...devices['Pixel 7'] });
    const p = await ctx.newPage();
    p.on('pageerror', e => errs.push('pageerror: ' + e.message));
    p.on('console', m => { if (m.type() === 'error') errs.push('console: ' + m.text()); });

    // 1) anciennes données en localStorage -> reprises dans IndexedDB
    await p.goto(URL_ + "manifest.json");
    await p.evaluate(() => localStorage.setItem("salle_assiette_v1", JSON.stringify({ config: null, foods: {}, recipes: {}, days: { "2026-11-20": { meals: [{ name: "Test migration", g: 100, p: 30, k: 200 }], weight: 72.5 } }, sessions: {} })));
    await p.goto(URL_); await p.waitForTimeout(1500);
    console.log("1. Migration :", JSON.stringify(await p.evaluate(() => ({ ancienneCle: localStorage.getItem("salle_assiette_v1"), copieSecours: !!localStorage.getItem("salle_assiette_v1_avant_idb"), mode: Store.mode, poidsRepris: S.days["2026-11-20"] && S.days["2026-11-20"].weight }))));

    // 2) écriture puis relecture après rechargement
    await p.evaluate(() => put("days", "2026-11-21", { meals: [], weight: 73.1 }));
    await p.waitForTimeout(400); await p.reload(); await p.waitForTimeout(1200);
    console.log("2. Relu après rechargement :", await p.evaluate(() => S.days["2026-11-21"] && S.days["2026-11-21"].weight));

    // 3) installabilité selon Chrome
    const cdp = await ctx.newCDPSession(p);
    console.log("3. Erreurs d'installabilité :", JSON.stringify((await cdp.send('Page.getInstallabilityErrors')).installabilityErrors));
    const man = await cdp.send('Page.getAppManifest'); console.log("   Manifest :", man.url, "erreurs :", JSON.stringify(man.errors));
    console.log("   Service worker :", await p.evaluate(async () => { const r = await navigator.serviceWorker.getRegistration(); return (r && r.active ? "actif" : "inactif") + " scope=" + (r && r.scope); }), "| page contrôlée :", await p.evaluate(() => !!navigator.serviceWorker.controller));
    console.log("   PWA.on :", await p.evaluate(() => PWA.on), "| état installation :", await p.evaluate(() => installState()));
    await p.screenshot({ path: SP + "/android-home.png" });

    // 4) hors-ligne
    await ctx.setOffline(true); await p.reload(); await p.waitForTimeout(1200);
    console.log("4. Hors-ligne : titre =", await p.title(), "| app affichée =", await p.evaluate(() => document.getElementById("app").innerText.length > 50), "| données lues =", await p.evaluate(() => S.days["2026-11-21"] && S.days["2026-11-21"].weight));
    await ctx.setOffline(false);

    // 5) mise à jour : on modifie la page servie -> le bouton doit apparaître
    const fs = require('fs'), f = require('path').resolve(__dirname, '../index.html'), orig = fs.readFileSync(f, 'utf8');
    fs.writeFileSync(f, orig + "\n<!-- test maj -->");
    try { await p.reload(); await p.waitForTimeout(2000); console.log("5. Bouton « Nouvelle version » :", await p.evaluate(() => !!document.getElementById("maj"))); }
    finally { fs.writeFileSync(f, orig); }

    // 6) iPhone simulé (Chromium, pas Safari)
    const ic = await b.newContext({ ...devices['iPhone 15 Pro'] }); const ip = await ic.newPage();
    ip.on('pageerror', e => errs.push('ios pageerror: ' + e.message));
    await ip.goto(URL_); await ip.waitForTimeout(1500);
    console.log("6. iPhone : état installation =", await ip.evaluate(() => installState()));
    await ip.screenshot({ path: SP + "/ios-home.png" });
    await ip.click('[data-act="install"]'); await ip.waitForTimeout(700); await ip.screenshot({ path: SP + "/ios-guide.png" });
    await ip.click('#sh [data-act="installHide"]'); await ip.waitForTimeout(500);
    console.log("   Bandeau masqué après « J'ai compris » :", await ip.evaluate(() => !document.querySelector('#app [data-act="install"]')));
  } finally {
    console.log("Erreurs JS :", errs.length ? errs : "aucune");
    await b.close(); srv.close();
  }
})();
