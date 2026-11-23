-- Test des règles d'accès (RLS) avec 3 faux utilisateurs. Tout est annulé à la fin (rollback) : rien ne reste.
-- A et B deviennent amis ; C est un inconnu. Une erreur « ÉCHEC … » arrête le test.
begin;
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000c', 'c@test.local', 'authenticated', 'authenticated');

set local role authenticated;

-- A : écrit ses données, son résumé, et demande B en ami
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
insert into public.docs (col, id, data) values ('days', '2026-11-23', '{"weight": 70, "meals": []}');
insert into public.summaries (data) values ('{"semaine": 2}');
insert into public.friendships (addressee) values ('00000000-0000-0000-0000-00000000000b');
do $$ begin
  if (select count(*) from public.profiles) <> 3 then raise exception 'ÉCHEC : profils non créés automatiquement'; end if;
  begin insert into public.friendships (requester, addressee, status) values ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-00000000000c','accepted');
        raise exception 'ÉCHEC : A a pu créer une amitié déjà acceptée';
  exception when insufficient_privilege then null; end;
end $$;

-- B : ne voit rien de A avant d'accepter
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.docs) <> 0 then raise exception 'ÉCHEC : B voit les données privées de A'; end if;
  if (select count(*) from public.summaries) <> 0 then raise exception 'ÉCHEC : B voit le résumé de A avant amitié'; end if;
  if (select count(*) from public.friendships) <> 1 then raise exception 'ÉCHEC : B ne voit pas la demande reçue'; end if;
end $$;
update public.friendships set status = 'accepted' where requester = '00000000-0000-0000-0000-00000000000a';
do $$ begin
  if (select count(*) from public.summaries) <> 1 then raise exception 'ÉCHEC : B ne voit pas le résumé de son ami A'; end if;
  if (select count(*) from public.docs) <> 0 then raise exception 'ÉCHEC : B voit les données privées de son ami A'; end if;
  begin insert into public.docs (user_id, col, id, data) values ('00000000-0000-0000-0000-00000000000a','days','x','{}');
        raise exception 'ÉCHEC : B a écrit dans les données de A';
  exception when insufficient_privilege then null; end;
  update public.summaries set data = '{"pirate": true}' where user_id = '00000000-0000-0000-0000-00000000000a';
end $$;
insert into public.reactions (to_user, kind) values ('00000000-0000-0000-0000-00000000000a', '💪');

-- C : inconnu, ne voit rien et ne peut pas réagir
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.summaries) <> 0 then raise exception 'ÉCHEC : C voit le résumé de A'; end if;
  if (select count(*) from public.friendships) <> 0 then raise exception 'ÉCHEC : C voit les amitiés des autres'; end if;
  if (select count(*) from public.reactions) <> 0 then raise exception 'ÉCHEC : C voit les réactions des autres'; end if;
  begin insert into public.reactions (to_user, kind) values ('00000000-0000-0000-0000-00000000000a', '🔥');
        raise exception 'ÉCHEC : C a pu réagir sans être ami';
  exception when insufficient_privilege then null; end;
end $$;

-- A : son résumé n'a pas été modifié par B ; il coupe le partage
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
do $$ begin
  if (select data->>'pirate' from public.summaries) is not null then raise exception 'ÉCHEC : B a modifié le résumé de A'; end if;
  if (select count(*) from public.reactions) <> 1 then raise exception 'ÉCHEC : A ne voit pas la réaction reçue'; end if;
end $$;
update public.summaries set share = false;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.summaries) <> 0 then raise exception 'ÉCHEC : B voit le résumé alors que A a coupé le partage'; end if;
end $$;

-- Visiteur non connecté : rien
set local role anon;
do $$ begin
  begin
    if (select count(*) from public.profiles) <> 0 then raise exception 'ÉCHEC : un visiteur non connecté voit les profils'; end if;
  exception when insufficient_privilege then null; -- refus d'office : c'est ce qu'on veut
  end;
  begin
    perform 1 from public.docs limit 1; raise exception 'ÉCHEC : un visiteur non connecté peut lire les données';
  exception when insufficient_privilege then null;
  end;
end $$;

rollback;
select 'Tous les tests RLS sont passés' as resultat;
