# Backend Supabase — Salle & Assiette

Projet Supabase : **salle-assiette** (réf. `pdhrxoybtjxtkwjhkfxy`, région `eu-west-1` Irlande, UE).

| Élément public (peut être dans le code de l'appli) | Valeur |
|---|---|
| URL du projet | `https://pdhrxoybtjxtkwjhkfxy.supabase.co` |
| Clé publique (publishable) | `sb_publishable_arbwPZTwAEFCvmC1bLqrJw_8HwZicso` |

Ces deux valeurs sont **publiques par conception** : la sécurité vient des règles d'accès (RLS) de la base.
Les clés `secret` / `service_role` ne doivent **jamais** apparaître dans ce dépôt ni dans l'appli.

## Tables

| Table | Contenu | Qui y accède |
|---|---|---|
| `profiles` | pseudo, nom affiché, emoji (créé automatiquement à l'inscription) | lecture : utilisateurs connectés · modification : soi |
| `docs` | un document de l'appli par ligne (`config`, `foods`, `recipes`, `days`, `sessions`), même contenu que l'objet `S` | **propriétaire uniquement** |
| `friendships` | demande d'ami (`pending`) puis amitié (`accepted`) | les deux personnes concernées ; seul le destinataire accepte |
| `summaries` | résumé de progression partageable (pas de poids ni de repas), avec interrupteur `share` | soi + amis acceptés (si `share`) |
| `reactions` | 💪 🔥 👏 🏆 envoyés à un ami | envoyeur et destinataire ; envoi seulement à un ami |
| `push_subscriptions` | abonnements aux rappels (notifications) | propriétaire uniquement |

Visiteur non connecté : **aucun accès** (refusé d'office).

## Migrations (dans l'ordre, déjà appliquées)
1. `001_schema_initial.sql` : tables, déclencheur de profil, règles RLS.
2. `002_droits_api.sql` : droits explicites pour les utilisateurs connectés (les nouveaux projets n'ouvrent plus rien par défaut).
3. `003_fonctions_privees.sql` : fonctions internes non appelables depuis l'API (alertes de sécurité Supabase corrigées).
4. `004_performance.sql` : optimisations recommandées par Supabase.

Pour un nouveau projet : coller les 4 fichiers dans l'éditeur SQL de Supabase, dans l'ordre.

## Tests
`tests/rls.sql` : 3 faux utilisateurs (A et B amis, C inconnu), tout est annulé à la fin. Vérifie notamment :
un ami ne voit jamais les données privées, ne peut ni les modifier ni modifier le résumé ; un inconnu ne voit rien et ne peut pas réagir ;
couper le partage masque le résumé ; un visiteur non connecté est refusé.
Résultat au 23/11/2026 : **tous passés**. Contrôles Supabase : **0 alerte de sécurité, 0 alerte de performance**.

## Connexion
- Par **code à 6 chiffres** reçu par e-mail (valable 10 min), sans mot de passe à retenir.
  Pas de « lien magique » : sur iPhone il s'ouvrirait dans Safari, dont le stockage est séparé de l'appli installée.
- ⚠️ **À faire avant d'ouvrir au public** : brancher un service d'envoi d'e-mails (SMTP). Sans lui, Supabase n'envoie que
  2 e-mails/heure, réservés aux tests, et refuse de modifier le modèle d'e-mail. Le modèle prêt à coller : `emails/code-connexion.html`.
- Adresse de l'appli (`site_url`) à régler quand l'adresse Cloudflare Pages sera connue.
