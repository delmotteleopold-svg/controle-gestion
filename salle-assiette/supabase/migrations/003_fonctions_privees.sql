-- Corrige les 3 alertes du contrôle de sécurité Supabase :
-- les fonctions internes ne doivent pas être appelables depuis l'API (/rest/v1/rpc/...).

-- 1) Création de profil : seulement par le déclencheur d'inscription, jamais appelable à la main.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- 2) « Sont-ils amis ? » : déplacée dans un schéma « private » que l'API n'expose pas.
--    Les règles RLS l'utilisent toujours, mais personne ne peut l'appeler pour sonder les amitiés des autres.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create function private.are_friends(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester = a and f.addressee = b) or (f.requester = b and f.addressee = a))
  );
$$;
revoke all on function private.are_friends(uuid, uuid) from public, anon;
grant execute on function private.are_friends(uuid, uuid) to authenticated;

drop policy "résumé : lire (moi ou ami)" on public.summaries;
create policy "résumé : lire (moi ou ami)" on public.summaries for select to authenticated
  using (user_id = auth.uid() or (share and private.are_friends(auth.uid(), user_id)));
drop policy "réactions : envoyer à un ami" on public.reactions;
create policy "réactions : envoyer à un ami" on public.reactions for insert to authenticated
  with check (from_user = auth.uid() and private.are_friends(from_user, to_user));

drop function public.are_friends(uuid, uuid);
