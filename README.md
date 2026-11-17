# controle-gestion

« Ma vie d'étudiant » : petite application web installable (PWA) pour suivre son budget, ses révisions et sa lecture.
Tout est dans `index.html` (HTML, CSS et JavaScript) ; `sw.js` permet d'ouvrir l'appli sans connexion.

## Où sont les données ?

Dans le navigateur de l'appareil (`localStorage`), sous les clés `cg.budgets`, `cg.expenses`, `cg.revision`,
`cg.reading`, `cg.reco` (et `cg.gcal` pour l'identifiant Google Agenda, qui n'est jamais exporté).

## Sauvegarder et restaurer (onglet Budget, tout en bas)

- **Exporter mes données** : télécharge un fichier JSON `mes-depenses-AAAA-MM-JJ.json` (budgets, dépenses, révision, lecture, recommandations).
- **Importer une sauvegarde** : relit ce fichier.
  - Le fichier est vérifié en entier avant tout : s'il est invalide, un message l'explique et **rien n'est modifié**.
  - Une confirmation résume le contenu du fichier à côté de ce qu'il y a aujourd'hui.
  - Les blocs absents du fichier sont conservés tels quels ; les blocs présents sont remplacés.
  - Une copie des données d'avant est gardée (`cg.avant-import`) : **Annuler le dernier import** les remet en place.
    Ce qui a été saisi après l'import est alors perdu.
