-- May's Games: progress tracking for Seun's private dashboard (maysgame.pages.dev/stats).
-- Covers every game: Paint Sudoku, Colouring Book, Picture Logic, Fruit Slash, Free Paint and the Hair Studio.
-- HOW TO USE: Supabase → SQL Editor → New query → paste this whole file → replace CHANGE-ME below → Run.
-- Safe to run again any time (for example to change the passcode).

create table if not exists public.salon_events (
  id bigserial primary key,
  at timestamptz not null default now(),
  device text not null,
  kind text not null,
  data jsonb not null default '{}'::jsonb
);
create index if not exists salon_events_at on public.salon_events (at desc);
create index if not exists salon_events_dev on public.salon_events (device, at desc);
alter table public.salon_events enable row level security;
revoke all on public.salon_events from anon, authenticated;

create table if not exists public.salon_admin (key text primary key, value text not null);
alter table public.salon_admin enable row level security;
revoke all on public.salon_admin from anon, authenticated;
-- PASSCODE: change CHANGE-ME to your own passcode before running
insert into public.salon_admin (key, value) values ('code', 'CHANGE-ME')
  on conflict (key) do update set value = excluded.value;

create or replace function public.salon_log(p_device text, p_kind text, p_data jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_device is null or length(p_device) > 40 or p_kind not in ('open', 'client', 'unlock', 'ping') then return; end if;
  if octet_length(coalesce(p_data, '{}'::jsonb)::text) > 16000 then return; end if;
  if (select count(*) from salon_events where device = p_device and at > now() - interval '1 minute') >= 20 then return; end if;
  insert into salon_events (device, kind, data) values (p_device, p_kind, coalesce(p_data, '{}'::jsonb));
end $$;
revoke all on function public.salon_log(text, text, jsonb) from public;
grant execute on function public.salon_log(text, text, jsonb) to anon, authenticated;

create or replace function public.get_salon(p_code text)
returns json language plpgsql security definer set search_path = public as $$
declare r json;
begin
  if not exists (select 1 from salon_admin where key = 'code' and value = p_code and value <> 'CHANGE-ME') then
    raise exception 'Wrong passcode';
  end if;
  select json_build_object(
    'online', (select count(distinct device) from salon_events where at > now() - interval '2 minutes'),
    'players', coalesce((select json_agg(p order by p.last_seen desc) from (
        select e.device, min(e.at) as first_seen, max(e.at) as last_seen,
               count(*) filter (where e.kind = 'open') as opens,
               count(*) filter (where e.kind = 'client') as clients,
               count(distinct (e.at at time zone 'Africa/Lagos')::date) as days_played,
               (select x.data from salon_events x where x.device = e.device and x.kind in ('open', 'client')
                 order by x.at desc limit 1) - 'thumb' as latest
        from salon_events e group by e.device) p), '[]'::json),
    'daily', coalesce((select json_agg(d order by d.day) from (
        select (at at time zone 'Africa/Lagos')::date as day,
               count(*) filter (where kind = 'open') as opens,
               count(*) filter (where kind = 'client') as clients
        from salon_events where at > now() - interval '14 days' group by 1) d), '[]'::json),
    'clients', coalesce((select json_agg(c order by c.at desc) from (
        select at, device, data from salon_events where kind = 'client' order by at desc limit 60) c), '[]'::json),
    'unlocks', coalesce((select json_agg(u order by u.at desc) from (
        select at, device, data from salon_events where kind = 'unlock' order by at desc limit 30) u), '[]'::json)
  ) into r;
  return r;
end $$;
revoke all on function public.get_salon(text) from public;
grant execute on function public.get_salon(text) to anon, authenticated;


-- =====================================================================
-- All games (dashboard home: maysgame.pages.dev/stats). Uses the same passcode as above.
-- =====================================================================
create table if not exists public.mg_events (
  id bigserial primary key,
  at timestamptz not null default now(),
  device text not null,
  game text not null,
  kind text not null,
  data jsonb not null default '{}'::jsonb
);
create index if not exists mg_events_at on public.mg_events (at desc);
create index if not exists mg_events_dev on public.mg_events (device, at desc);
alter table public.mg_events enable row level security;
revoke all on public.mg_events from anon, authenticated;

create or replace function public.mg_log(p_device text, p_game text, p_kind text, p_data jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_device is null or length(p_device) > 40 or p_kind not in ('open', 'play', 'win', 'snap', 'ping') then return; end if;
  if p_game is null or p_game not in ('home', 'sudoku', 'colour', 'logic', 'fruit', 'paint', 'salon') then return; end if;
  if octet_length(coalesce(p_data, '{}'::jsonb)::text) > 8000 then return; end if;
  if (select count(*) from mg_events where device = p_device and at > now() - interval '1 minute') >= 30 then return; end if;
  insert into mg_events (device, game, kind, data) values (p_device, p_game, p_kind, coalesce(p_data, '{}'::jsonb));
end $$;
revoke all on function public.mg_log(text, text, text, jsonb) from public;
grant execute on function public.mg_log(text, text, text, jsonb) to anon, authenticated;

create or replace function public.get_mays(p_code text)
returns json language plpgsql security definer set search_path = public as $$
declare r json;
begin
  if not exists (select 1 from salon_admin where key = 'code' and value = p_code and value <> 'CHANGE-ME') then
    raise exception 'Wrong passcode';
  end if;
  select json_build_object(
    'now', now(),
    'online', (select json_agg(distinct game) from mg_events where at > now() - interval '2 minutes' and kind in ('ping', 'play', 'open', 'win')),
    'devices', coalesce((select json_agg(d order by d.last_seen desc) from (
        select device, min(at) as first_seen, max(at) as last_seen,
               count(distinct (at at time zone 'Africa/Lagos')::date) as days_played
        from mg_events group by device) d), '[]'::json),
    'snap', (select json_build_object('at', at, 'data', data) from mg_events where kind = 'snap' order by at desc limit 1),
    'daily', coalesce((select json_agg(d order by d.day) from (
        select (at at time zone 'Africa/Lagos')::date as day, count(*) filter (where kind = 'play') as plays,
               count(*) filter (where kind = 'win') as wins, count(distinct game) filter (where kind = 'play') as games
        from mg_events where at > now() - interval '14 days' group by 1) d), '[]'::json),
    'games7', coalesce((select json_object_agg(game, n) from (
        select game, count(*) as n from mg_events where kind = 'play' and at > now() - interval '7 days' group by game) g), '{}'::json),
    'wins', coalesce((select json_agg(w order by w.at desc) from (
        select at, game, data from mg_events where kind = 'win' order by at desc limit 40) w), '[]'::json)
  ) into r;
  return r;
end $$;
revoke all on function public.get_mays(text) from public;
grant execute on function public.get_mays(text) to anon, authenticated;
