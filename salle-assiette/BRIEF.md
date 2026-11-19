# Salle & Assiette : brief

Appli perso de Leo : suivi des séances (charges, progression), du poids et de l'alimentation (protéines, calories).

## Fonctionnement technique
- Un seul fichier : `index.html` (HTML + CSS + JS, aucune librairie).
- Version officielle hébergée par Claude (artifact privé) : `window.claude.use("db")` pour le stockage cloud, `use("sample")` pour l'estimation des repas par photo/texte, `use("downloads")` pour l'export.
- Ailleurs (GitHub Pages, navigateur local), ces fonctions sont absentes : l'appli marche quand même avec `localStorage`. Ne jamais casser ce repli.
- Contraintes de la version hébergée : pas d'images distantes, pas de `alert/confirm/prompt`, scripts externes seulement depuis cdnjs/jsdelivr/unpkg, polices seulement via Google Fonts.

## Ne pas toucher
- La logique des données (objet `S`, fonctions `put`, `queue`, `flush`, `initCloud`), la règle de suggestion de charge (`suggest`), les noms de champs enregistrés.

## Identité visuelle actuelle
Fond beige, vert + orange, coins très arrondis, barre de navigation flottante façon Instagram.

## Exporter mes données (Réglages › Sauvegarde › Exporter)
- **Tout, réimportable (.json)** : même format qu'avant (`{app:"salle-assiette", v:1, date, config, foods, recipes, days, sessions}`), relu par « Importer ».
- **Historique lisible (.csv)**, séparateur `;`, décimales à virgule, encodage UTF-8 avec BOM (accents corrects dans Excel) :
  - `salle-assiette-seances-AAAA-MM-JJ.csv` : date, seance, heure_debut, duree_min, exercice, serie (É = échauffement), type, charge_kg, reps, validee (séances terminées uniquement).
  - `salle-assiette-poids-…csv` : date, poids_kg.
  - `salle-assiette-repas-…csv` : date, heure, repas, quantite_g, proteines_g, kcal.
  - `salle-assiette-jours-…csv` : date, proteines_g, kcal, objectif_proteines_atteint, poids_kg, seances.
- Version Claude : le fichier passe par `use("downloads")` (confirmation à chaque fichier). Ailleurs : lien de téléchargement du navigateur. Si rien ne marche : texte à copier.
- La date du dernier export est gardée sur l'appareil (`salle_assiette_export`, hors données) et affichée dans Réglages.

## Thème
Clair ou sombre selon le téléphone ; dans claude.ai, le choix clair/sombre du site (`data-theme`) l'emporte.

## Balayage entre onglets
Accueil ↔ Séance ↔ Repas ↔ Progrès d'un glissé horizontal, sur le modèle de la pagination iOS (celle d'Instagram) :
- la page suit le doigt 1:1, la page voisine arrive collée ; l'onglet de la barre suit en direct ;
- le geste ne démarre qu'après 10 px et si le mouvement est plus horizontal que vertical (×1,15), sinon le défilement vertical reste normal ;
- aux bords (Accueil à gauche, Progrès à droite) : élastique iOS `(1 − 1/(x·0,55/l + 1))·l` ;
- changement de page si on dépasse la moitié de l'écran ou sur un coup de doigt > 0,3 px/ms ; sinon retour ;
- arrivée en 200 à 380 ms selon la vitesse du doigt (courbe `cubic-bezier(.2,.9,.3,1)`) ;
- pas de balayage dans les champs, les stepper de charge/reps, la barre du bas ni quand une fenêtre est ouverte.

## Version installée sur l'écran d'accueil (GitHub Pages)
Sur `*.github.io`, la page ajoute un manifest (icône intégrée) et enregistre `salle-assiette/sw.js` pour s'ouvrir sans réseau.
`sw.js` ne nettoie que les caches `salle-assiette-…` : il ne touche jamais au cache de l'appli à la racine.
Dans cette version, les données restent sur le téléphone (pas de cloud Claude ni d'estimation photo) : exporter régulièrement.
