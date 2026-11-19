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
