-- Optimisations recommandées par le contrôle de performance Supabase (aucun changement de comportement) :
-- 1) (select auth.uid()) est calculé une fois par requête au lieu d'une fois par ligne.
-- 2) index sur les clés étrangères utilisées par les règles et les suppressions en cascade.

drop policy "profil modifiable par soi" on public.profiles;
create policy "profil modifiable par soi" on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy "docs : propriétaire" on public.docs;
create policy "docs : propriétaire" on public.docs for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy "amis : voir les miens" on public.friendships;
create policy "amis : voir les miens" on public.friendships for select to authenticated
  using ((select auth.uid()) in (requester, addressee));
drop policy "amis : demander" on public.friendships;
create policy "amis : demander" on public.friendships for insert to authenticated
  with check (requester = (select auth.uid()) and status = 'pending');
drop policy "amis : accepter" on public.friendships;
create policy "amis : accepter" on public.friendships for update to authenticated
  using (addressee = (select auth.uid())) with check (addressee = (select auth.uid()) and status = 'accepted');
drop policy "amis : retirer" on public.friendships;
create policy "amis : retirer" on public.friendships for delete to authenticated
  using ((select auth.uid()) in (requester, addressee));

drop policy "résumé : lire (moi ou ami)" on public.summaries;
create policy "résumé : lire (moi ou ami)" on public.summaries for select to authenticated
  using (user_id = (select auth.uid()) or (share and private.are_friends((select auth.uid()), user_id)));
drop policy "résumé : écrire le mien" on public.summaries;
create policy "résumé : écrire le mien" on public.summaries for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy "résumé : modifier le mien" on public.summaries;
create policy "résumé : modifier le mien" on public.summaries for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy "réactions : envoyer à un ami" on public.reactions;
create policy "réactions : envoyer à un ami" on public.reactions for insert to authenticated
  with check (from_user = (select auth.uid()) and private.are_friends(from_user, to_user));
drop policy "réactions : voir" on public.reactions;
create policy "réactions : voir" on public.reactions for select to authenticated
  using ((select auth.uid()) in (from_user, to_user));
drop policy "réactions : retirer" on public.reactions;
create policy "réactions : retirer" on public.reactions for delete to authenticated
  using (from_user = (select auth.uid()));

drop policy "push : propriétaire" on public.push_subscriptions;
create policy "push : propriétaire" on public.push_subscriptions for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create index if not exists friendships_addressee on public.friendships (addressee);
create index if not exists reactions_from on public.reactions (from_user);
create index if not exists push_subscriptions_user on public.push_subscriptions (user_id);
