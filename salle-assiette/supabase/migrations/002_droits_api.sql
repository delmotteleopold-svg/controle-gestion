-- Droits d'accès par l'API pour les utilisateurs connectés (rôle « authenticated »).
-- Les nouveaux projets Supabase n'ouvrent plus les tables automatiquement : on accorde le strict nécessaire.
-- Les règles RLS (001) restent le filtre ligne par ligne. Le rôle « anon » (non connecté) n'a aucun droit.
grant usage on schema public to authenticated;
grant select, update                 on public.profiles           to authenticated;
grant select, insert, update, delete on public.docs               to authenticated;
grant select, insert, update, delete on public.friendships        to authenticated;
grant select, insert, update         on public.summaries          to authenticated;
grant select, insert, delete         on public.reactions          to authenticated;
grant select, insert, update, delete on public.push_subscriptions to authenticated;
revoke all on public.profiles, public.docs, public.friendships, public.summaries, public.reactions, public.push_subscriptions from anon;
