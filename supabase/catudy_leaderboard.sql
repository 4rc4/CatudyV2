create table if not exists public.catudy_leaderboard (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Guest Cat',
  pet_id text not null default 'mochi',
  pet_name text not null default 'Mochi',
  equipped_pet_item_id text,
  room_item_ids jsonb not null default '{}'::jsonb,
  points integer not null default 0,
  total_minutes integer not null default 0,
  streak_days integer not null default 0,
  sessions_count integer not null default 0,
  favorite_category text not null default '',
  stats_public boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.catudy_leaderboard
  add column if not exists pet_name text not null default 'Mochi',
  add column if not exists equipped_pet_item_id text,
  add column if not exists room_item_ids jsonb not null default '{}'::jsonb,
  add column if not exists sessions_count integer not null default 0,
  add column if not exists favorite_category text not null default '',
  add column if not exists stats_public boolean not null default true;

alter table public.catudy_leaderboard enable row level security;

drop policy if exists "Catudy leaderboard is readable" on public.catudy_leaderboard;
drop policy if exists "Users can create their leaderboard row" on public.catudy_leaderboard;
drop policy if exists "Users can update their leaderboard row" on public.catudy_leaderboard;

create policy "Catudy leaderboard is readable"
on public.catudy_leaderboard
for select
to anon, authenticated
using (true);

create policy "Users can create their leaderboard row"
on public.catudy_leaderboard
for insert
to anon, authenticated
with check (auth.uid() = user_id);

create policy "Users can update their leaderboard row"
on public.catudy_leaderboard
for update
to anon, authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create index if not exists catudy_leaderboard_points_idx
on public.catudy_leaderboard (points desc, total_minutes desc);

create or replace view public.catudy_public_profiles as
select
  user_id,
  display_name,
  pet_id,
  pet_name,
  equipped_pet_item_id,
  room_item_ids,
  case when stats_public then points else 0 end as points,
  case when stats_public then total_minutes else 0 end as total_minutes,
  case when stats_public then streak_days else 0 end as streak_days,
  case when stats_public then sessions_count else 0 end as sessions_count,
  case when stats_public then favorite_category else '' end as favorite_category,
  stats_public,
  updated_at
from public.catudy_leaderboard;

grant select on public.catudy_public_profiles to anon, authenticated;

do $$
begin
  alter publication supabase_realtime add table public.catudy_leaderboard;
exception
  when duplicate_object then null;
end $$;
