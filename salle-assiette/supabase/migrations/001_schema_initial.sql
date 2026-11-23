-- Salle & Assiette : schéma initial (Supabase / PostgreSQL)
-- Appliqué au projet « salle-assiette » le 23/11/2026.
--
-- Principes
-- 1. Chaque utilisateur ne voit et ne modifie QUE ses propres données (RLS = règles d'accès vérifiées par la base).
-- 2. Les données de l'appli sont gardées telles quelles : une ligne par document de l'appli
--    (config/main, foods/…, recipes/…, days/AAAA-MM-JJ, sessions/…), dans « docs ». Cela reprend exactement
--    la logique put(col, id, val) de l'appli : la synchro hors-ligne est simple (le plus récent gagne).
-- 3. Un ami ne voit JAMAIS ces documents : il voit seulement un RÉSUMÉ de progression (« summaries »),
--    calculé par l'appli et choisi pour être partageable (séances, records, régularité ; pas de poids ni de repas).
-- 4. Rappels : abonnements aux notifications (« push_subscriptions »), utilisés plus tard par une fonction serveur.

-- ============ Profils ============
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text unique check (username ~ '^[a-z0-9_.]{3,20}$'),   -- pseudo pour être trouvé par ses amis
  display_name text check (char_length(display_name) <= 40),
  avatar       text check (char_length(avatar) <= 8),                  -- un emoji
  created_at   timestamptz not null default now()
);
comment on table public.profiles is 'Profil public minimal : pseudo, nom affiché, emoji. Visible des utilisateurs connectés (recherche d''amis).';

-- Création automatique du profil à l'inscription
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name) values (new.id, nullif(split_part(coalesce(new.email, ''), '@', 1), ''));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============ Données de l'appli (privées) ============
create table public.docs (
  user_id    uuid not null references auth.users(id) on delete cascade default auth.uid(),
  col        text not null check (col in ('config', 'foods', 'recipes', 'days', 'sessions')),
  id         text not null check (char_length(id) between 1 and 80),
  data       jsonb,                                  -- null si supprimé
  deleted    boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, col, id)
);
create index docs_user_updated on public.docs (user_id, updated_at);
comment on table public.docs is 'Un document de l''appli par ligne (même contenu que l''objet S). Privé : seul le propriétaire y accède.';

create function public.touch_updated_at() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end $$;
create trigger docs_touch before update on public.docs for each row execute function public.touch_updated_at();

-- ============ Amis ============
create table public.friendships (
  requester  uuid not null references auth.users(id) on delete cascade default auth.uid(),
  addressee  uuid not null references auth.users(id) on delete cascade,
  status     text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  primary key (requester, addressee),
  check (requester <> addressee)
);
create unique index friendships_pair on public.friendships (least(requester, addressee), greatest(requester, addressee));
comment on table public.friendships is 'Demande d''ami (pending) puis amitié (accepted). Une seule ligne par paire.';

create function public.are_friends(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester = a and f.addressee = b) or (f.requester = b and f.addressee = a))
  );
$$;

-- ============ Résumé de progression (partagé avec les amis) ============
create table public.summaries (
  user_id    uuid primary key references auth.users(id) on delete cascade default auth.uid(),
  data       jsonb not null default '{}'::jsonb,   -- ex. {semaine: 3, objectif: 4, serie_semaines: 5, records: [...], tendance: ...}
  share      boolean not null default true,         -- l'utilisateur peut couper le partage
  updated_at timestamptz not null default now()
);
create trigger summaries_touch before update on public.summaries for each row execute function public.touch_updated_at();
comment on table public.summaries is 'Résumé de progression calculé par l''appli. Lisible par le propriétaire et ses amis acceptés (si share = true).';

-- ============ Réactions (interagir avec les amis) ============
create table public.reactions (
  id         bigint generated always as identity primary key,
  from_user  uuid not null references auth.users(id) on delete cascade default auth.uid(),
  to_user    uuid not null references auth.users(id) on delete cascade,
  kind       text not null check (kind in ('💪', '🔥', '👏', '🏆')),
  created_at timestamptz not null default now(),
  check (from_user <> to_user)
);
create index reactions_to on public.reactions (to_user, created_at desc);

-- ============ Rappels (notifications push) ============
create table public.push_subscriptions (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users(id) on delete cascade default auth.uid(),
  endpoint   text not null unique,
  p256dh     text not null,
  auth       text not null,
  settings   jsonb not null default '{}'::jsonb,   -- ex. {seance: {jours: [1,3,5], heure: "18:00"}, proteines: {heure: "20:30"}}
  timezone   text not null default 'Europe/Paris',
  created_at timestamptz not null default now()
);

-- ============ Règles d'accès (RLS) ============
alter table public.profiles           enable row level security;
alter table public.docs               enable row level security;
alter table public.friendships        enable row level security;
alter table public.summaries          enable row level security;
alter table public.reactions          enable row level security;
alter table public.push_subscriptions enable row level security;

-- profils : lisibles par tout utilisateur connecté (pour trouver un ami), modifiables par soi seul
create policy "profils lisibles (connectés)" on public.profiles for select to authenticated using (true);
create policy "profil modifiable par soi"    on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- docs : propriétaire uniquement
create policy "docs : propriétaire" on public.docs for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- amis : je vois les liens qui me concernent ; je demande en mon nom ; seul le destinataire accepte ; chacun peut supprimer
create policy "amis : voir les miens"  on public.friendships for select to authenticated using (auth.uid() in (requester, addressee));
create policy "amis : demander"        on public.friendships for insert to authenticated with check (requester = auth.uid() and status = 'pending');
create policy "amis : accepter"        on public.friendships for update to authenticated using (addressee = auth.uid()) with check (addressee = auth.uid() and status = 'accepted');
create policy "amis : retirer"         on public.friendships for delete to authenticated using (auth.uid() in (requester, addressee));

-- résumés : le mien en écriture ; ceux de mes amis en lecture s'ils partagent
create policy "résumé : lire (moi ou ami)" on public.summaries for select to authenticated
  using (user_id = auth.uid() or (share and public.are_friends(auth.uid(), user_id)));
create policy "résumé : écrire le mien"    on public.summaries for insert to authenticated with check (user_id = auth.uid());
create policy "résumé : modifier le mien"  on public.summaries for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- réactions : envoyer seulement à un ami ; voir celles que j'ai envoyées ou reçues ; retirer les miennes
create policy "réactions : envoyer à un ami" on public.reactions for insert to authenticated
  with check (from_user = auth.uid() and public.are_friends(from_user, to_user));
create policy "réactions : voir"    on public.reactions for select to authenticated using (auth.uid() in (from_user, to_user));
create policy "réactions : retirer" on public.reactions for delete to authenticated using (from_user = auth.uid());

-- abonnements push : propriétaire uniquement
create policy "push : propriétaire" on public.push_subscriptions for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Les visiteurs non connectés (rôle anon) n'ont accès à rien : aucune règle ne les autorise.
revoke all on function public.are_friends(uuid, uuid) from public, anon;
grant execute on function public.are_friends(uuid, uuid) to authenticated;
