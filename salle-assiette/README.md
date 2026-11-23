# Salle & Assiette : web app installable (PWA)

Suivi de musculation (charges, séries, répétitions, suggestion de charge) et d'alimentation (protéines, calories),
installable sur iPhone et Android, utilisable hors-ligne.

> Pour le fonctionnement détaillé de l'appli (export, balayage, aliments à l'unité, estimation photo…), voir [`BRIEF.md`](BRIEF.md).
> Ce README couvre la partie **PWA** : installation, hors-ligne, stockage, déploiement, tests, et la feuille de route.

## Stack (choix et raisons)

**HTML + CSS + JavaScript sans framework ni étape de compilation, stockage IndexedDB, hébergement statique en HTTPS.**
- L'appli existante marche ainsi : la réécrire (React, Vite…) coûterait des semaines sans bénéfice visible pour l'utilisateur.
- Toutes les lectures/écritures passent par un seul module (`Store` + `put`) : le backend s'y branchera sans toucher aux écrans.
- Aucun outil à installer pour publier : on dépose le dossier `salle-assiette/` sur l'hébergeur.

## Fichiers

| Fichier | Rôle |
|---|---|
| `index.html` | Toute l'appli (écrans, logique, styles) |
| `manifest.json` | Carte d'identité de l'appli pour l'installation : nom, couleurs, mode plein écran (`standalone`), icônes, raccourcis |
| `sw.js` | Service worker : ouverture instantanée et hors-ligne, détection des nouvelles versions |
| `icons/` | `icon-192.png`, `icon-512.png`, `icon-maskable-512.png` (marge de sécurité pour les formes Android), `apple-touch-icon.png`, `favicon-32.png`, `icon.svg` (source vectorielle) |
| `_headers` | En-têtes HTTP pour Cloudflare Pages / Netlify (pas de cache sur `sw.js` et `manifest.json`) |
| `tests/` | Tests automatiques (voir plus bas) |

## Ce qui a été fait (étapes 1 à 4)

### 1. Manifest et icônes
- `manifest.json` statique (avant : manifest fabriqué en JavaScript sous forme de `data:`, seulement sur `*.github.io`).
- Icônes 192 et 512 px, icône *maskable* 512 px, icône iOS 180 px (gardée aussi dans `index.html`, pour qu'elle marche partout).
- Raccourcis (appui long sur l'icône, Android) : « Démarrer une séance » (`./#gym`), « Ajouter un repas » (`./#food`).
- **Activation automatique** : la page cherche `manifest.json` à côté d'elle. S'il existe (GitHub Pages, Cloudflare, Netlify, localhost), la PWA s'active ; sinon (version claude.ai) rien ne change.

### 2. Service worker v2 (`sw.js`)
- À l'installation : copie de la page, du manifest et des icônes.
- Ouverture : la copie gardée s'affiche **tout de suite** (même sans réseau à la salle), et la dernière version est téléchargée en parallèle.
- Si la page a changé : bouton vert **« Nouvelle version · Mettre à jour »** en haut de l'écran (enregistre puis recharge).
- Ne touche qu'aux caches `salle-assiette-…` (jamais à l'appli à la racine du dépôt). Les appels à l'API Claude et au futur backend ne passent pas par le cache.
- Changer `VERSION` dans `sw.js` seulement si la liste des fichiers copiés change.

### 3. Installation
- **Android (Chrome)** : l'invitation d'installation est interceptée et proposée par un bandeau « Installer l'appli » sur l'accueil, et dans Réglages › Appli.
- **iPhone (Safari)** : iOS n'a pas de bouton d'installation automatique ; le même bandeau ouvre un guide en 3 étapes (Partager → Sur l'écran d'accueil → Ajouter).
- Le bandeau disparaît une fois l'appli installée, ou après « J'ai compris » / la croix (`localStorage` `salle_assiette_install_masque`).
- Déjà en place avant : balises `apple-mobile-web-app-*`, `theme-color` clair/sombre, `viewport-fit=cover` et marges `env(safe-area-inset-*)` pour l'encoche.

### 4. Stockage IndexedDB
- Base `salle-assiette`, magasin `etat`, clé `S` : tout l'objet `S` en JSON (même contenu qu'avant, mêmes noms de champs).
- **Reprise automatique** à la première ouverture : les données de `localStorage` (`salle_assiette_v1`) sont copiées dans IndexedDB, puis rangées sous `salle_assiette_v1_avant_idb` (copie de secours, plus relue).
- **Repli** : si IndexedDB est indisponible, l'appli reste sur `localStorage` comme avant (`Store.mode` vaut alors `"ls"`).
- Écriture 150 ms après chaque modification, et **immédiatement** quand l'appli passe en arrière-plan.
- Appli installée : demande au navigateur de ne pas effacer les données (`navigator.storage.persist()`).
- Inchangés : `S`, `put`, `queue`, `flush`, `initCloud`, `suggest`. La version claude.ai garde son cloud.

## Tests

```bash
npm i -D playwright
```

```bash
node salle-assiette/tests/pwa.test.js
```

Ce que le test vérifie (Chromium, Pixel 7 et iPhone 15 Pro simulés) : reprise des données `localStorage` → IndexedDB, relecture après rechargement,
**installabilité selon Chrome** (`Page.getInstallabilityErrors` vide), service worker actif, ouverture hors-ligne, bouton de mise à jour, guide iOS, aucune erreur JavaScript.

Résultats au 22/11/2026 : tous les tests passent. Replis vérifiés aussi : sans `manifest.json` (comme sur claude.ai) l'appli marche sans PWA ; sans IndexedDB elle repasse sur `localStorage`.

**Lighthouse (mobile)** : Performance 100 · Accessibilité 93 · Bonnes pratiques 100 · SEO 100 (affichage complet en 1,6 s).
- Note : Google a retiré la catégorie « PWA » de Lighthouse en 2024 (version 12). L'installabilité est donc vérifiée par le test ci-dessus (même contrôle que Chrome).
- Contrastes corrigés avec le système de couleurs à 3 rôles (voir `BRIEF.md` › Système de couleurs). Seul point restant : le zoom bloqué (ci-dessous), voulu.
- `maximum-scale=1` est gardé exprès : sans lui, iPhone zoome à chaque saisie de charge.
- « Compression du texte » : assurée automatiquement par Cloudflare Pages / Netlify (pas par le serveur de test).

### À tester sur un vrai iPhone (2 minutes, Safari)
Le test automatique simule l'écran d'un iPhone dans Chromium, mais **pas Safari**. À vérifier à la main après déploiement :
1. Ouvrir l'adresse dans Safari → le bandeau « Installer l'appli » apparaît → le guide s'ouvre.
2. Partager → Sur l'écran d'accueil → l'icône (anneaux vert et orange) est nette.
3. Ouvrir depuis l'icône : plein écran, rien caché sous l'encoche ni sous la barre du bas.
4. Saisir une série, fermer l'appli, mode Avion, rouvrir : l'appli s'ouvre et la série est là.

## Déploiement (HTTPS obligatoire pour l'installation)

**Important pour un usage commercial** :
- GitHub Pages interdit les sites dont le but principal est commercial ou SaaS. Il convient pour les tests, pas pour le lancement.
- Le plan gratuit de Vercel (Hobby) est réservé à un usage non commercial.
- **Recommandé : Cloudflare Pages** (gratuit, usage commercial accepté, bande passante illimitée au moment de l'écriture) ; Netlify en alternative. Vérifier les conditions à l'inscription.

Mise en ligne sur Cloudflare Pages (une seule fois, environ 5 minutes) :
1. Créer un compte Cloudflare → Workers & Pages → Create → Pages → *Connect to Git* → choisir ce dépôt.
2. Build command : *(vide)*. Build output directory : `salle-assiette`.
3. Chaque `git push` sur la branche choisie republie l'appli automatiquement.

## Feuille de route

| Étape | Contenu | État |
|---|---|---|
| 1–4 | PWA : manifest, icônes, hors-ligne, installation, IndexedDB | ✅ fait et testé |
| — | Système de couleurs : vert + orange = données, violet = actions | ✅ fait et testé |
| 5a | Backend Supabase : tables, règles d'accès, tests de sécurité (voir [`supabase/README.md`](supabase/README.md)) | ✅ fait et testé |
| 5b | Dans l'appli : connexion par code, synchronisation multi-appareils | à faire |
| 6 | **Progression** enrichie (priorité n°1) | à faire |
| 7 | **Amis** : ajouter un ami, voir un résumé de sa progression, réagir | à faire (après 5) |
| 8 | **Rappels** (notifications Web Push) | à faire (après 5) |
