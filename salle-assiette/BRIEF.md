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
