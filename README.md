# controle-gestion

« Ma vie d'étudiant » : petite application web installable (PWA) pour suivre son budget, ses révisions et sa lecture.
Tout est dans `index.html` (HTML, CSS et JavaScript) ; `sw.js` permet d'ouvrir l'appli sans connexion.

> Le dossier [`salle-assiette/`](salle-assiette/README.md) contient une deuxième appli, **Salle & Assiette** (sport et alimentation), avec son propre README.

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

## Copie pour mes agents (Google Sheets, onglet Budget, tout en bas)

Le bouton **Synchroniser avec Google Sheets** écrit une **copie** de tes données dans un Google Sheets privé de ton Drive,
que des assistants (Claude, tâches planifiées) peuvent lire quand l'appli est fermée.

- **Sens unique** : appli vers Sheets. L'appli ne relit jamais le fichier, donc aucun conflit. Pour corriger une donnée, on la corrige dans l'appli.
- **Droit Google** : `drive.file`, c'est-à-dire uniquement les fichiers créés par l'appli. L'Agenda garde son droit à part (`calendar.readonly`).
- **Jeton Google** : gardé en mémoire seulement (jamais écrit dans le navigateur ni dans le fichier). Il faut donc appuyer sur le bouton au moins une fois à chaque ouverture de l'appli ; ensuite, la copie suit les modifications toute seule (8 s après la dernière).
- **Où est le fichier** : `cg.sheets` (identifiant, lien, date). Cette clé n'est pas dans la sauvegarde exportée.
- **Prérequis Google Cloud** (une seule fois, dans le projet qui contient l'identifiant client de l'Agenda) : activer *Google Sheets API*, et ajouter le droit `.../auth/drive.file` à l'écran de consentement.

### Format de la copie (schema_version 1)

Tout est réécrit à chaque synchro. Dates AAAA-MM-JJ (texte), montants en euros, durées en minutes. L'onglet `Lisez_moi` donne la date de synchro
et le nombre de lignes attendu par onglet : s'il ne correspond pas, la synchro a été interrompue.

| Onglet | Colonnes |
|---|---|
| `Depenses` | id, date, montant_eur, categorie, note |
| `Budgets` | categorie, budget_mensuel_eur |
| `Reglages` | cle, valeur (objectifs quotidiens de révision et de lecture) |
| `Revision_cours` | cours, objectif_min_avant_ds |
| `Revision_sessions` | id, date, cours, minutes |
| `Revision_DS` | id, date, cours, source (`agenda` ou `manuel`) |
| `Lecture_livres` | id, titre, pages, page_actuelle, statut (`reading` ou `done`) |
| `Lecture_sessions` | id, date, livre_id, livre, minutes, pages_lues |
| `Livres_a_lire` | id, titre, auteurs, pages, categories |
