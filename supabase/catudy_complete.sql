-- Catudy complete Supabase schema.
-- Run this whole file once in the Supabase SQL Editor.
-- It is idempotent and can be run again after app updates.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Leaderboard and public profiles
-- ---------------------------------------------------------------------------

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
  add column if not exists display_name text not null default 'Guest Cat',
  add column if not exists pet_id text not null default 'mochi',
  add column if not exists pet_name text not null default 'Mochi',
  add column if not exists equipped_pet_item_id text,
  add column if not exists room_item_ids jsonb not null default '{}'::jsonb,
  add column if not exists points integer not null default 0,
  add column if not exists total_minutes integer not null default 0,
  add column if not exists streak_days integer not null default 0,
  add column if not exists sessions_count integer not null default 0,
  add column if not exists favorite_category text not null default '',
  add column if not exists stats_public boolean not null default true,
  add column if not exists updated_at timestamptz not null default now();

alter table public.catudy_leaderboard enable row level security;

drop policy if exists "Catudy leaderboard is readable"
  on public.catudy_leaderboard;
create policy "Catudy leaderboard is readable"
  on public.catudy_leaderboard
  for select
  to anon, authenticated
  using (true);

drop policy if exists "Users can create their leaderboard row"
  on public.catudy_leaderboard;
create policy "Users can create their leaderboard row"
  on public.catudy_leaderboard
  for insert
  to anon, authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their leaderboard row"
  on public.catudy_leaderboard;
create policy "Users can update their leaderboard row"
  on public.catudy_leaderboard
  for update
  to anon, authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update on public.catudy_leaderboard
  to anon, authenticated;

create index if not exists catudy_leaderboard_points_idx
  on public.catudy_leaderboard (points desc, total_minutes desc);

create index if not exists catudy_leaderboard_total_minutes_idx
  on public.catudy_leaderboard (total_minutes desc, points desc);

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

-- ---------------------------------------------------------------------------
-- Private local-first user backups
-- ---------------------------------------------------------------------------

create table if not exists public.catudy_user_backups (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state_version integer not null default 2,
  data jsonb not null default '{}'::jsonb,
  client_updated_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.catudy_user_backups
  add column if not exists state_version integer not null default 2,
  add column if not exists data jsonb not null default '{}'::jsonb,
  add column if not exists client_updated_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.catudy_user_backups enable row level security;

drop policy if exists "users can read their backup"
  on public.catudy_user_backups;
create policy "users can read their backup"
  on public.catudy_user_backups
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "users can create their backup"
  on public.catudy_user_backups;
create policy "users can create their backup"
  on public.catudy_user_backups
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "users can update their backup"
  on public.catudy_user_backups;
create policy "users can update their backup"
  on public.catudy_user_backups
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update on public.catudy_user_backups
  to authenticated;

-- ---------------------------------------------------------------------------
-- Premium entitlements and Buddy Passes
-- ---------------------------------------------------------------------------

create table if not exists public.catudy_premium_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  source text not null default 'none'
    check (source in ('none', 'subscription', 'buddyPass')),
  activated_at timestamptz,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.catudy_premium_entitlements
  add column if not exists source text not null default 'none',
  add column if not exists activated_at timestamptz,
  add column if not exists expires_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

alter table public.catudy_premium_entitlements
  drop constraint if exists catudy_premium_entitlements_source_check;
alter table public.catudy_premium_entitlements
  add constraint catudy_premium_entitlements_source_check
  check (source in ('none', 'subscription', 'buddyPass'));

create table if not exists public.catudy_buddy_passes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  redeemed_by_user_id uuid references auth.users(id) on delete set null,
  redeemed_at timestamptz,
  redeemer_start_minutes integer not null default 0,
  sender_reward_granted_at timestamptz
);

alter table public.catudy_buddy_passes
  add column if not exists code text,
  add column if not exists sender_user_id uuid
    references auth.users(id) on delete cascade,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists expires_at timestamptz,
  add column if not exists redeemed_by_user_id uuid
    references auth.users(id) on delete set null,
  add column if not exists redeemed_at timestamptz,
  add column if not exists redeemer_start_minutes integer not null default 0,
  add column if not exists sender_reward_granted_at timestamptz;

create unique index if not exists catudy_buddy_passes_code_idx
  on public.catudy_buddy_passes (code);
create index if not exists catudy_buddy_passes_sender_month_idx
  on public.catudy_buddy_passes (sender_user_id, created_at desc);

create table if not exists public.catudy_buddy_pass_redemptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  buddy_pass_id uuid not null unique
    references public.catudy_buddy_passes(id) on delete cascade,
  buddy_pass_code text not null,
  redeemed_at timestamptz not null default now()
);

create table if not exists public.catudy_reward_grants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reward_key text not null,
  source_type text not null,
  source_id uuid not null,
  created_at timestamptz not null default now(),
  unique (user_id, reward_key, source_type, source_id)
);

alter table public.catudy_reward_grants
  add column if not exists user_id uuid
    references auth.users(id) on delete cascade,
  add column if not exists reward_key text,
  add column if not exists source_type text,
  add column if not exists source_id uuid,
  add column if not exists created_at timestamptz not null default now();

create unique index if not exists catudy_reward_grants_unique_idx
  on public.catudy_reward_grants (user_id, reward_key, source_type, source_id);

alter table public.catudy_buddy_pass_redemptions
  add column if not exists buddy_pass_id uuid
    references public.catudy_buddy_passes(id) on delete cascade,
  add column if not exists buddy_pass_code text,
  add column if not exists redeemed_at timestamptz not null default now();

alter table public.catudy_premium_entitlements enable row level security;
alter table public.catudy_buddy_passes enable row level security;
alter table public.catudy_buddy_pass_redemptions enable row level security;
alter table public.catudy_reward_grants enable row level security;

drop policy if exists "users can read their premium entitlement"
  on public.catudy_premium_entitlements;
create policy "users can read their premium entitlement"
  on public.catudy_premium_entitlements
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "users can read sent or redeemed buddy passes"
  on public.catudy_buddy_passes;
create policy "users can read sent or redeemed buddy passes"
  on public.catudy_buddy_passes
  for select
  to authenticated
  using (
    auth.uid() = sender_user_id
    or auth.uid() = redeemed_by_user_id
  );

drop policy if exists "users can read their buddy redemption"
  on public.catudy_buddy_pass_redemptions;
create policy "users can read their buddy redemption"
  on public.catudy_buddy_pass_redemptions
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "users can read their reward grants"
  on public.catudy_reward_grants;
create policy "users can read their reward grants"
  on public.catudy_reward_grants
  for select
  to authenticated
  using (auth.uid() = user_id);

grant select on public.catudy_premium_entitlements
  to authenticated;
grant select on public.catudy_buddy_passes
  to authenticated;
grant select on public.catudy_buddy_pass_redemptions
  to authenticated;
grant select on public.catudy_reward_grants
  to authenticated;

create or replace function public.catudy_has_active_premium(target_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.catudy_premium_entitlements e
    where e.user_id = target_user_id
      and e.source <> 'none'
      and (e.expires_at is null or e.expires_at > now())
  );
$$;

create or replace function public.catudy_create_buddy_pass()
returns table (
  code text,
  created_at timestamptz,
  expires_at timestamptz,
  redeemed_by_user_id uuid,
  redeemed_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  generated_code text;
begin
  if current_user_id is null then
    raise exception 'authentication required';
  end if;

  if not public.catudy_has_active_premium(current_user_id) then
    raise exception 'active premium required';
  end if;

  if exists (
    select 1
    from public.catudy_buddy_passes p
    where p.sender_user_id = current_user_id
      and date_trunc('month', p.created_at) = date_trunc('month', now())
  ) then
    raise exception 'monthly buddy pass already used';
  end if;

  loop
    generated_code := 'PLUS-' || upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 8));
    exit when not exists (
      select 1
      from public.catudy_buddy_passes p
      where p.code = generated_code
    );
  end loop;

  insert into public.catudy_buddy_passes (
    code,
    sender_user_id,
    expires_at
  )
  values (
    generated_code,
    current_user_id,
    now() + interval '30 days'
  )
  returning
    catudy_buddy_passes.code,
    catudy_buddy_passes.created_at,
    catudy_buddy_passes.expires_at,
    catudy_buddy_passes.redeemed_by_user_id,
    catudy_buddy_passes.redeemed_at
  into
    code,
    created_at,
    expires_at,
    redeemed_by_user_id,
    redeemed_at;

  return next;
end;
$$;

create or replace function public.catudy_redeem_buddy_pass(pass_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_pass public.catudy_buddy_passes%rowtype;
begin
  if current_user_id is null then
    return false;
  end if;

  if public.catudy_has_active_premium(current_user_id) then
    return false;
  end if;

  if exists (
    select 1
    from public.catudy_buddy_pass_redemptions r
    where r.user_id = current_user_id
  ) then
    return false;
  end if;

  select *
  into target_pass
  from public.catudy_buddy_passes p
  where p.code = upper(trim(pass_code))
  for update;

  if not found
    or target_pass.sender_user_id = current_user_id
    or target_pass.redeemed_at is not null
    or target_pass.expires_at <= now() then
    return false;
  end if;

  update public.catudy_buddy_passes
  set
    redeemed_by_user_id = current_user_id,
    redeemed_at = now(),
    redeemer_start_minutes = coalesce(
      (
        select total_minutes
        from public.catudy_leaderboard
        where user_id = current_user_id
      ),
      0
    )
  where id = target_pass.id;

  insert into public.catudy_buddy_pass_redemptions (
    user_id,
    buddy_pass_id,
    buddy_pass_code
  )
  values (
    current_user_id,
    target_pass.id,
    target_pass.code
  );

  insert into public.catudy_premium_entitlements (
    user_id,
    source,
    activated_at,
    expires_at,
    updated_at
  )
  values (
    current_user_id,
    'buddyPass',
    now(),
    now() + interval '30 days',
    now()
  )
  on conflict (user_id) do update
  set
    source = excluded.source,
    activated_at = excluded.activated_at,
    expires_at = excluded.expires_at,
    updated_at = excluded.updated_at;

  return true;
end;
$$;

create or replace function public.catudy_award_buddy_pass_sender_reward()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  qualifying_pass public.catudy_buddy_passes%rowtype;
begin
  select *
  into qualifying_pass
  from public.catudy_buddy_passes p
  where p.redeemed_by_user_id = new.user_id
    and p.sender_reward_granted_at is null
    and new.total_minutes - p.redeemer_start_minutes >= 180
  order by p.redeemed_at desc
  limit 1
  for update;

  if not found then
    return new;
  end if;

  update public.catudy_buddy_passes
  set sender_reward_granted_at = now()
  where id = qualifying_pass.id;

  insert into public.catudy_reward_grants (
    user_id,
    reward_key,
    source_type,
    source_id
  )
  values (
    qualifying_pass.sender_user_id,
    'buddy_moon_pin',
    'buddy_pass',
    qualifying_pass.id
  )
  on conflict (user_id, reward_key, source_type, source_id) do nothing;

  return new;
end;
$$;

drop trigger if exists catudy_award_buddy_pass_sender_reward_trigger
  on public.catudy_leaderboard;
create trigger catudy_award_buddy_pass_sender_reward_trigger
after insert or update of total_minutes
on public.catudy_leaderboard
for each row
execute function public.catudy_award_buddy_pass_sender_reward();

grant execute on function public.catudy_create_buddy_pass()
  to authenticated;
grant execute on function public.catudy_redeem_buddy_pass(text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Social graph, friend requests, blocks, and reports
-- ---------------------------------------------------------------------------

create table if not exists public.catudy_friend_requests (
  id uuid primary key default gen_random_uuid(),
  requester_user_id uuid not null references auth.users(id) on delete cascade,
  receiver_user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_user_id <> receiver_user_id)
);

alter table public.catudy_friend_requests
  add column if not exists requester_user_id uuid
    references auth.users(id) on delete cascade,
  add column if not exists receiver_user_id uuid
    references auth.users(id) on delete cascade,
  add column if not exists status text not null default 'pending',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists responded_at timestamptz;

alter table public.catudy_friend_requests
  drop constraint if exists catudy_friend_requests_status_check;
alter table public.catudy_friend_requests
  add constraint catudy_friend_requests_status_check
  check (status in ('pending', 'accepted', 'rejected', 'cancelled'));

create unique index if not exists catudy_friend_requests_pair_pending_idx
  on public.catudy_friend_requests (requester_user_id, receiver_user_id)
  where status = 'pending';

create table if not exists public.catudy_friends (
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  friend_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (owner_user_id, friend_user_id),
  check (owner_user_id <> friend_user_id)
);

create table if not exists public.catudy_blocked_users (
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (owner_user_id, blocked_user_id),
  check (owner_user_id <> blocked_user_id)
);

create table if not exists public.catudy_profile_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null default 'profile',
  status text not null default 'open'
    check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  check (reporter_user_id <> reported_user_id)
);

alter table public.catudy_profile_reports
  add column if not exists reason text not null default 'profile',
  add column if not exists status text not null default 'open',
  add column if not exists reviewed_at timestamptz;

alter table public.catudy_profile_reports
  drop constraint if exists catudy_profile_reports_status_check;
alter table public.catudy_profile_reports
  add constraint catudy_profile_reports_status_check
  check (status in ('open', 'reviewing', 'resolved', 'dismissed'));

alter table public.catudy_friend_requests enable row level security;
alter table public.catudy_friends enable row level security;
alter table public.catudy_blocked_users enable row level security;
alter table public.catudy_profile_reports enable row level security;

drop policy if exists "friend requests are visible to participants"
  on public.catudy_friend_requests;
create policy "friend requests are visible to participants"
  on public.catudy_friend_requests
  for select
  to authenticated
  using (
    auth.uid() = requester_user_id
    or auth.uid() = receiver_user_id
  );

drop policy if exists "users can create their friend requests"
  on public.catudy_friend_requests;
create policy "users can create their friend requests"
  on public.catudy_friend_requests
  for insert
  to authenticated
  with check (
    auth.uid() = requester_user_id
    and status = 'pending'
    and requester_user_id <> receiver_user_id
  );

drop policy if exists "receivers can respond to friend requests"
  on public.catudy_friend_requests;
create policy "receivers can respond to friend requests"
  on public.catudy_friend_requests
  for update
  to authenticated
  using (auth.uid() = receiver_user_id)
  with check (
    auth.uid() = receiver_user_id
    and status in ('accepted', 'rejected')
  );

drop policy if exists "requesters can cancel friend requests"
  on public.catudy_friend_requests;
create policy "requesters can cancel friend requests"
  on public.catudy_friend_requests
  for update
  to authenticated
  using (auth.uid() = requester_user_id)
  with check (
    auth.uid() = requester_user_id
    and status = 'cancelled'
  );

drop policy if exists "friend rows are visible to owner"
  on public.catudy_friends;
create policy "friend rows are visible to owner"
  on public.catudy_friends
  for select
  to authenticated
  using (auth.uid() = owner_user_id);

drop policy if exists "users can add their accepted friends"
  on public.catudy_friends;
create policy "users can add their accepted friends"
  on public.catudy_friends
  for insert
  to authenticated
  with check (auth.uid() = owner_user_id);

drop policy if exists "users can remove their friends"
  on public.catudy_friends;
create policy "users can remove their friends"
  on public.catudy_friends
  for delete
  to authenticated
  using (auth.uid() = owner_user_id or auth.uid() = friend_user_id);

drop policy if exists "blocked users are visible to owner"
  on public.catudy_blocked_users;
create policy "blocked users are visible to owner"
  on public.catudy_blocked_users
  for select
  to authenticated
  using (auth.uid() = owner_user_id);

drop policy if exists "users can create blocked users"
  on public.catudy_blocked_users;
create policy "users can create blocked users"
  on public.catudy_blocked_users
  for insert
  to authenticated
  with check (auth.uid() = owner_user_id);

drop policy if exists "users can remove blocked users"
  on public.catudy_blocked_users;
create policy "users can remove blocked users"
  on public.catudy_blocked_users
  for delete
  to authenticated
  using (auth.uid() = owner_user_id);

drop policy if exists "users can report profiles"
  on public.catudy_profile_reports;
create policy "users can report profiles"
  on public.catudy_profile_reports
  for insert
  to authenticated
  with check (auth.uid() = reporter_user_id);

drop policy if exists "users can view their own reports"
  on public.catudy_profile_reports;
create policy "users can view their own reports"
  on public.catudy_profile_reports
  for select
  to authenticated
  using (auth.uid() = reporter_user_id);

grant select, insert, update on public.catudy_friend_requests
  to authenticated;
grant select, insert, delete on public.catudy_friends
  to authenticated;
grant select, insert, delete on public.catudy_blocked_users
  to authenticated;
grant select, insert on public.catudy_profile_reports
  to authenticated;

create or replace function public.catudy_accept_friend_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'accepted' and old.status = 'pending' then
    insert into public.catudy_friends (owner_user_id, friend_user_id)
    values
      (new.requester_user_id, new.receiver_user_id),
      (new.receiver_user_id, new.requester_user_id)
    on conflict do nothing;

    new.responded_at = coalesce(new.responded_at, now());
  elsif new.status in ('rejected', 'cancelled') and old.status = 'pending' then
    new.responded_at = coalesce(new.responded_at, now());
  end if;

  return new;
end;
$$;

drop trigger if exists catudy_accept_friend_request_trigger
  on public.catudy_friend_requests;
create trigger catudy_accept_friend_request_trigger
  before update of status on public.catudy_friend_requests
  for each row
  execute function public.catudy_accept_friend_request();

-- ---------------------------------------------------------------------------
-- Realtime focus lobbies
-- ---------------------------------------------------------------------------

create table if not exists public.catudy_lobbies (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  category_id text not null default 'study',
  duration_minutes integer not null default 25
    check (duration_minutes between 1 and 240),
  status text not null default 'waiting'
    check (status in ('waiting', 'running', 'finished')),
  started_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.catudy_lobbies
  add column if not exists category_id text not null default 'study',
  add column if not exists duration_minutes integer not null default 25,
  add column if not exists status text not null default 'waiting',
  add column if not exists started_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

alter table public.catudy_lobbies
  drop constraint if exists catudy_lobbies_duration_minutes_check;
alter table public.catudy_lobbies
  add constraint catudy_lobbies_duration_minutes_check
  check (duration_minutes between 1 and 240);

alter table public.catudy_lobbies
  drop constraint if exists catudy_lobbies_status_check;
alter table public.catudy_lobbies
  add constraint catudy_lobbies_status_check
  check (status in ('waiting', 'running', 'finished'));

create index if not exists catudy_lobbies_code_idx
  on public.catudy_lobbies (code);

create table if not exists public.catudy_lobby_members (
  id uuid primary key default gen_random_uuid(),
  lobby_id uuid not null references public.catudy_lobbies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default 'Guest Cat',
  ready boolean not null default false,
  owner boolean not null default false,
  connected boolean not null default true,
  break_vote boolean,
  break_vote_updated_at timestamptz,
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (lobby_id, user_id)
);

alter table public.catudy_lobby_members
  add column if not exists display_name text not null default 'Guest Cat',
  add column if not exists ready boolean not null default false,
  add column if not exists owner boolean not null default false,
  add column if not exists connected boolean not null default true,
  add column if not exists break_vote boolean,
  add column if not exists break_vote_updated_at timestamptz,
  add column if not exists joined_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists catudy_lobby_members_lobby_user_idx
  on public.catudy_lobby_members (lobby_id, user_id);

alter table public.catudy_lobbies enable row level security;
alter table public.catudy_lobby_members enable row level security;

drop policy if exists "authenticated users can read lobbies"
  on public.catudy_lobbies;
create policy "authenticated users can read lobbies"
  on public.catudy_lobbies
  for select
  to authenticated
  using (true);

drop policy if exists "users can create owned lobbies"
  on public.catudy_lobbies;
create policy "users can create owned lobbies"
  on public.catudy_lobbies
  for insert
  to authenticated
  with check (auth.uid() = owner_user_id);

drop policy if exists "owners can update lobbies"
  on public.catudy_lobbies;
create policy "owners can update lobbies"
  on public.catudy_lobbies
  for update
  to authenticated
  using (auth.uid() = owner_user_id)
  with check (auth.uid() = owner_user_id);

drop policy if exists "authenticated users can read lobby members"
  on public.catudy_lobby_members;
create policy "authenticated users can read lobby members"
  on public.catudy_lobby_members
  for select
  to authenticated
  using (true);

drop policy if exists "users can join as themselves"
  on public.catudy_lobby_members;
create policy "users can join as themselves"
  on public.catudy_lobby_members
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and (
      owner = false
      or exists (
        select 1
        from public.catudy_lobbies l
        where l.id = lobby_id
          and l.owner_user_id = auth.uid()
      )
    )
  );

drop policy if exists "users can update their lobby member row"
  on public.catudy_lobby_members;
create policy "users can update their lobby member row"
  on public.catudy_lobby_members
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and (
      owner = false
      or exists (
        select 1
        from public.catudy_lobbies l
        where l.id = lobby_id
          and l.owner_user_id = auth.uid()
      )
    )
  );

grant select, insert, update on public.catudy_lobbies
  to authenticated;
grant select, insert, update on public.catudy_lobby_members
  to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime publication. Missing publication is ignored for non-Supabase DBs.
-- ---------------------------------------------------------------------------

do $$
begin
  alter publication supabase_realtime add table public.catudy_leaderboard;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.catudy_friend_requests;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.catudy_friends;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.catudy_blocked_users;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.catudy_lobbies;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.catudy_lobby_members;
exception
  when duplicate_object or undefined_object then null;
end $$;
