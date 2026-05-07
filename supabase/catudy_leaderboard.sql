create table if not exists public.catudy_leaderboard (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Guest Cat',
  pet_id text not null default 'mochi',
  points integer not null default 0,
  total_minutes integer not null default 0,
  streak_days integer not null default 0,
  updated_at timestamptz not null default now()
);

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

do $$
begin
  alter publication supabase_realtime add table public.catudy_leaderboard;
exception
  when duplicate_object then null;
end $$;
