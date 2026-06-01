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
    generated_code := 'PLUS-' || upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 8));
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
-- Account deletion
-- ---------------------------------------------------------------------------

create or replace function public.catudy_delete_current_user()
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'authentication required';
  end if;

  update public.catudy_buddy_passes
  set
    redeemed_by_user_id = null,
    redeemed_at = null,
    redeemer_start_minutes = 0
  where redeemed_by_user_id = current_user_id;

  delete from auth.users
  where id = current_user_id;

  return found;
end;
$$;

revoke all on function public.catudy_delete_current_user() from public;
grant execute on function public.catudy_delete_current_user()
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
  paused_at timestamptz,
  paused_seconds integer not null default 0
    check (paused_seconds >= 0),
  pause_reason text
    check (pause_reason in ('manual', 'break')),
  break_vote_round integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.catudy_lobbies
  add column if not exists category_id text not null default 'study',
  add column if not exists duration_minutes integer not null default 25,
  add column if not exists status text not null default 'waiting',
  add column if not exists started_at timestamptz,
  add column if not exists paused_at timestamptz,
  add column if not exists paused_seconds integer not null default 0,
  add column if not exists pause_reason text,
  add column if not exists break_vote_round integer not null default 0,
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

alter table public.catudy_lobbies
  drop constraint if exists catudy_lobbies_paused_seconds_check;
alter table public.catudy_lobbies
  add constraint catudy_lobbies_paused_seconds_check
  check (paused_seconds >= 0);

alter table public.catudy_lobbies
  drop constraint if exists catudy_lobbies_pause_reason_check;
alter table public.catudy_lobbies
  add constraint catudy_lobbies_pause_reason_check
  check (pause_reason in ('manual', 'break'));

create index if not exists catudy_lobbies_code_idx
  on public.catudy_lobbies (code);

create table if not exists public.catudy_lobby_members (
  id uuid primary key default gen_random_uuid(),
  lobby_id uuid not null references public.catudy_lobbies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default 'Guest Cat',
  pet_id text not null default 'mochi',
  pet_name text not null default 'Mochi',
  equipped_pet_item_id text,
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
  add column if not exists pet_id text not null default 'mochi',
  add column if not exists pet_name text not null default 'Mochi',
  add column if not exists equipped_pet_item_id text,
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

drop policy if exists "lobby owners can update member rows"
  on public.catudy_lobby_members;
create policy "lobby owners can update member rows"
  on public.catudy_lobby_members
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.catudy_lobbies l
      where l.id = lobby_id
        and l.owner_user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.catudy_lobbies l
      where l.id = lobby_id
        and l.owner_user_id = auth.uid()
    )
  );

grant select, insert, update on public.catudy_lobbies
  to authenticated;
grant select, insert, update on public.catudy_lobby_members
  to authenticated;

create or replace function public.catudy_submit_lobby_break_vote(
  target_lobby_id uuid,
  approved boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_lobby public.catudy_lobbies%rowtype;
  member_count integer := 0;
  yes_count integer := 0;
  no_count integer := 0;
  needed_count integer := 1;
begin
  if current_user_id is null then
    return false;
  end if;

  select *
  into target_lobby
  from public.catudy_lobbies
  where id = target_lobby_id
    and status = 'running'
  for update;

  if not found or target_lobby.paused_at is not null then
    return false;
  end if;

  update public.catudy_lobby_members
  set
    break_vote = approved,
    break_vote_updated_at = now(),
    updated_at = now()
  where lobby_id = target_lobby_id
    and user_id = current_user_id
    and connected = true;

  if not found then
    return false;
  end if;

  select
    count(*),
    count(*) filter (where break_vote is true),
    count(*) filter (where break_vote is false)
  into member_count, yes_count, no_count
  from public.catudy_lobby_members
  where lobby_id = target_lobby_id
    and connected = true;

  needed_count := greatest(1, (member_count / 2) + 1);

  if yes_count >= needed_count then
    update public.catudy_lobbies
    set
      paused_at = now(),
      pause_reason = 'break',
      break_vote_round = break_vote_round + 1,
      updated_at = now()
    where id = target_lobby_id
      and status = 'running'
      and paused_at is null;

    update public.catudy_lobby_members
    set
      break_vote = null,
      break_vote_updated_at = now(),
      updated_at = now()
    where lobby_id = target_lobby_id;

    return true;
  end if;

  if no_count >= needed_count then
    update public.catudy_lobbies
    set
      break_vote_round = break_vote_round + 1,
      updated_at = now()
    where id = target_lobby_id;

    update public.catudy_lobby_members
    set
      break_vote = null,
      break_vote_updated_at = now(),
      updated_at = now()
    where lobby_id = target_lobby_id;
  end if;

  return false;
end;
$$;

grant execute on function public.catudy_submit_lobby_break_vote(uuid, boolean)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Publish hardening: server-owned writes and private-by-code lobbies
-- ---------------------------------------------------------------------------

create table if not exists public.catudy_focus_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_session_id text not null,
  category_id text not null default 'study',
  minutes integer not null check (minutes between 1 and 240),
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, client_session_id)
);

alter table public.catudy_focus_sessions enable row level security;

drop policy if exists "users can read their focus sessions"
  on public.catudy_focus_sessions;
create policy "users can read their focus sessions"
  on public.catudy_focus_sessions
  for select
  to authenticated
  using (auth.uid() = user_id);

revoke insert, update, delete on public.catudy_focus_sessions
  from anon, authenticated;
grant select on public.catudy_focus_sessions to authenticated;

drop policy if exists "Users can create their leaderboard row"
  on public.catudy_leaderboard;
drop policy if exists "Users can update their leaderboard row"
  on public.catudy_leaderboard;
revoke insert, update, delete on public.catudy_leaderboard
  from anon, authenticated;
grant select on public.catudy_leaderboard to anon, authenticated;

create or replace function public.catudy_current_focus_streak(p_user_id uuid)
returns integer
language sql
security definer
set search_path = public
as $$
  with days as (
    select distinct (completed_at at time zone 'utc')::date as focus_day
    from public.catudy_focus_sessions
    where user_id = p_user_id
  ),
  numbered as (
    select
      focus_day,
      focus_day + (row_number() over (order by focus_day desc))::integer as grp
    from days
    where focus_day <= (now() at time zone 'utc')::date
  )
  select coalesce(max(streak_count), 0)::integer
  from (
    select grp, count(*) as streak_count, max(focus_day) as latest_day
    from numbered
    group by grp
  ) streaks
  where latest_day >= (now() at time zone 'utc')::date - 1;
$$;

revoke all on function public.catudy_current_focus_streak(uuid) from public;

create or replace function public.catudy_refresh_leaderboard_stats(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total_minutes integer := 0;
  v_sessions_count integer := 0;
  v_favorite_category text := '';
begin
  select
    coalesce(sum(minutes), 0)::integer,
    count(*)::integer
  into v_total_minutes, v_sessions_count
  from public.catudy_focus_sessions
  where user_id = p_user_id;

  select category_id
  into v_favorite_category
  from public.catudy_focus_sessions
  where user_id = p_user_id
  group by category_id
  order by sum(minutes) desc, max(completed_at) desc
  limit 1;

  insert into public.catudy_leaderboard (
    user_id,
    points,
    total_minutes,
    streak_days,
    sessions_count,
    favorite_category,
    updated_at
  )
  values (
    p_user_id,
    v_total_minutes,
    v_total_minutes,
    public.catudy_current_focus_streak(p_user_id),
    v_sessions_count,
    coalesce(v_favorite_category, ''),
    now()
  )
  on conflict (user_id) do update
  set
    points = excluded.points,
    total_minutes = excluded.total_minutes,
    streak_days = excluded.streak_days,
    sessions_count = excluded.sessions_count,
    favorite_category = excluded.favorite_category,
    updated_at = excluded.updated_at;
end;
$$;

revoke all on function public.catudy_refresh_leaderboard_stats(uuid) from public;

create or replace function public.catudy_update_public_profile(
  p_display_name text,
  p_pet_id text,
  p_pet_name text,
  p_equipped_pet_item_id text,
  p_room_item_ids jsonb,
  p_stats_public boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  insert into public.catudy_leaderboard (
    user_id,
    display_name,
    pet_id,
    pet_name,
    equipped_pet_item_id,
    room_item_ids,
    stats_public,
    updated_at
  )
  values (
    v_user_id,
    coalesce(nullif(trim(p_display_name), ''), 'Guest Cat'),
    coalesce(nullif(trim(p_pet_id), ''), 'mochi'),
    coalesce(nullif(trim(p_pet_name), ''), 'White Cat'),
    p_equipped_pet_item_id,
    coalesce(p_room_item_ids, '{}'::jsonb),
    coalesce(p_stats_public, true),
    now()
  )
  on conflict (user_id) do update
  set
    display_name = excluded.display_name,
    pet_id = excluded.pet_id,
    pet_name = excluded.pet_name,
    equipped_pet_item_id = excluded.equipped_pet_item_id,
    room_item_ids = excluded.room_item_ids,
    stats_public = excluded.stats_public,
    updated_at = excluded.updated_at;

  return true;
end;
$$;

revoke all on function public.catudy_update_public_profile(text, text, text, text, jsonb, boolean)
  from public;
grant execute on function public.catudy_update_public_profile(text, text, text, text, jsonb, boolean)
  to authenticated;

create or replace function public.catudy_complete_focus_session(
  p_client_session_id text,
  p_category_id text,
  p_minutes integer,
  p_completed_at timestamptz default now()
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_inserted_count integer := 0;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if p_client_session_id is null or trim(p_client_session_id) = '' then
    raise exception 'client_session_id required';
  end if;
  if p_minutes is null or p_minutes < 1 or p_minutes > 240 then
    raise exception 'minutes out of range';
  end if;

  insert into public.catudy_focus_sessions (
    user_id,
    client_session_id,
    category_id,
    minutes,
    completed_at
  )
  values (
    v_user_id,
    trim(p_client_session_id),
    coalesce(nullif(trim(p_category_id), ''), 'study'),
    p_minutes,
    coalesce(p_completed_at, now())
  )
  on conflict (user_id, client_session_id) do nothing;

  get diagnostics v_inserted_count = row_count;
  perform public.catudy_refresh_leaderboard_stats(v_user_id);
  return v_inserted_count > 0;
end;
$$;

revoke all on function public.catudy_complete_focus_session(text, text, integer, timestamptz)
  from public;
grant execute on function public.catudy_complete_focus_session(text, text, integer, timestamptz)
  to authenticated;

drop policy if exists "users can create their friend requests"
  on public.catudy_friend_requests;
drop policy if exists "receivers can respond to friend requests"
  on public.catudy_friend_requests;
drop policy if exists "requesters can cancel friend requests"
  on public.catudy_friend_requests;
drop policy if exists "users can add their accepted friends"
  on public.catudy_friends;
drop policy if exists "users can remove their friends"
  on public.catudy_friends;
drop policy if exists "users can create blocked users"
  on public.catudy_blocked_users;
drop policy if exists "users can remove blocked users"
  on public.catudy_blocked_users;
drop policy if exists "users can report profiles"
  on public.catudy_profile_reports;

revoke insert, update, delete on public.catudy_friend_requests
  from authenticated;
revoke insert, update, delete on public.catudy_friends
  from authenticated;
revoke insert, update, delete on public.catudy_blocked_users
  from authenticated;
revoke insert, update, delete on public.catudy_profile_reports
  from authenticated;
grant select on public.catudy_friend_requests, public.catudy_friends,
  public.catudy_blocked_users, public.catudy_profile_reports
  to authenticated;

create or replace function public.catudy_send_friend_request(p_target_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id uuid;
begin
  if v_user_id is null or p_target_user_id is null or v_user_id = p_target_user_id then
    raise exception 'invalid friend request';
  end if;

  insert into public.catudy_friend_requests (
    requester_user_id,
    receiver_user_id,
    status
  )
  values (v_user_id, p_target_user_id, 'pending')
  returning id into v_request_id;

  return v_request_id;
end;
$$;

create or replace function public.catudy_respond_friend_request(
  p_request_id uuid,
  p_status text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request public.catudy_friend_requests%rowtype;
begin
  if v_user_id is null or p_status not in ('accepted', 'rejected', 'cancelled') then
    raise exception 'invalid friend response';
  end if;

  select *
  into v_request
  from public.catudy_friend_requests
  where id = p_request_id
    and status = 'pending'
  for update;

  if not found then
    return false;
  end if;
  if p_status = 'cancelled' and v_request.requester_user_id <> v_user_id then
    raise exception 'not allowed';
  end if;
  if p_status in ('accepted', 'rejected') and v_request.receiver_user_id <> v_user_id then
    raise exception 'not allowed';
  end if;

  update public.catudy_friend_requests
  set status = p_status, responded_at = now()
  where id = p_request_id;

  if p_status = 'accepted' then
    insert into public.catudy_friends (owner_user_id, friend_user_id)
    values
      (v_request.requester_user_id, v_request.receiver_user_id),
      (v_request.receiver_user_id, v_request.requester_user_id)
    on conflict do nothing;
  end if;

  return true;
end;
$$;

create or replace function public.catudy_remove_friend(p_target_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or p_target_user_id is null then
    raise exception 'authentication required';
  end if;
  delete from public.catudy_friends
  where (owner_user_id = v_user_id and friend_user_id = p_target_user_id)
     or (owner_user_id = p_target_user_id and friend_user_id = v_user_id);
  return true;
end;
$$;

create or replace function public.catudy_block_user(p_target_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or p_target_user_id is null or v_user_id = p_target_user_id then
    raise exception 'invalid block target';
  end if;
  insert into public.catudy_blocked_users (owner_user_id, blocked_user_id)
  values (v_user_id, p_target_user_id)
  on conflict do nothing;
  perform public.catudy_remove_friend(p_target_user_id);
  return true;
end;
$$;

create or replace function public.catudy_unblock_user(p_target_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or p_target_user_id is null then
    raise exception 'authentication required';
  end if;
  delete from public.catudy_blocked_users
  where owner_user_id = v_user_id
    and blocked_user_id = p_target_user_id;
  return true;
end;
$$;

create or replace function public.catudy_report_profile(p_target_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_report_id uuid;
begin
  if v_user_id is null or p_target_user_id is null or v_user_id = p_target_user_id then
    raise exception 'invalid report target';
  end if;
  insert into public.catudy_profile_reports (reporter_user_id, reported_user_id)
  values (v_user_id, p_target_user_id)
  returning id into v_report_id;
  return v_report_id;
end;
$$;

revoke all on function public.catudy_send_friend_request(uuid) from public;
revoke all on function public.catudy_respond_friend_request(uuid, text) from public;
revoke all on function public.catudy_remove_friend(uuid) from public;
revoke all on function public.catudy_block_user(uuid) from public;
revoke all on function public.catudy_unblock_user(uuid) from public;
revoke all on function public.catudy_report_profile(uuid) from public;
grant execute on function public.catudy_send_friend_request(uuid),
  public.catudy_respond_friend_request(uuid, text),
  public.catudy_remove_friend(uuid),
  public.catudy_block_user(uuid),
  public.catudy_unblock_user(uuid),
  public.catudy_report_profile(uuid)
  to authenticated;

create or replace function public.catudy_is_lobby_member(p_lobby_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.catudy_lobbies l
    where l.id = p_lobby_id
      and l.owner_user_id = auth.uid()
  )
  or exists (
    select 1
    from public.catudy_lobby_members m
    where m.lobby_id = p_lobby_id
      and m.user_id = auth.uid()
      and m.connected = true
  );
$$;

revoke all on function public.catudy_is_lobby_member(uuid) from public;

drop policy if exists "authenticated users can read lobbies"
  on public.catudy_lobbies;
drop policy if exists "users can create owned lobbies"
  on public.catudy_lobbies;
drop policy if exists "owners can update lobbies"
  on public.catudy_lobbies;
drop policy if exists "authenticated users can read lobby members"
  on public.catudy_lobby_members;
drop policy if exists "users can join as themselves"
  on public.catudy_lobby_members;
drop policy if exists "users can update their lobby member row"
  on public.catudy_lobby_members;
drop policy if exists "lobby owners can update member rows"
  on public.catudy_lobby_members;

create policy "lobbies are visible to participants"
  on public.catudy_lobbies
  for select
  to authenticated
  using (public.catudy_is_lobby_member(id));

create policy "lobby members are visible to participants"
  on public.catudy_lobby_members
  for select
  to authenticated
  using (public.catudy_is_lobby_member(lobby_id));

revoke insert, update, delete on public.catudy_lobbies
  from authenticated;
revoke insert, update, delete on public.catudy_lobby_members
  from authenticated;
grant select on public.catudy_lobbies, public.catudy_lobby_members
  to authenticated;

create or replace function public.catudy_create_lobby(
  p_code text,
  p_display_name text,
  p_pet_id text,
  p_pet_name text,
  p_equipped_pet_item_id text,
  p_category_id text,
  p_duration_minutes integer
)
returns public.catudy_lobbies
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_lobby public.catudy_lobbies%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  insert into public.catudy_lobbies (
    code,
    owner_user_id,
    category_id,
    duration_minutes,
    status
  )
  values (
    upper(trim(p_code)),
    v_user_id,
    coalesce(nullif(trim(p_category_id), ''), 'study'),
    least(greatest(coalesce(p_duration_minutes, 25), 1), 240),
    'waiting'
  )
  returning * into v_lobby;

  insert into public.catudy_lobby_members (
    lobby_id,
    user_id,
    display_name,
    pet_id,
    pet_name,
    equipped_pet_item_id,
    ready,
    owner,
    connected
  )
  values (
    v_lobby.id,
    v_user_id,
    coalesce(nullif(trim(p_display_name), ''), 'Guest Cat'),
    coalesce(nullif(trim(p_pet_id), ''), 'mochi'),
    coalesce(nullif(trim(p_pet_name), ''), 'White Cat'),
    p_equipped_pet_item_id,
    true,
    true,
    true
  );

  return v_lobby;
end;
$$;

create or replace function public.catudy_join_lobby(
  p_code text,
  p_display_name text,
  p_pet_id text,
  p_pet_name text,
  p_equipped_pet_item_id text
)
returns public.catudy_lobbies
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_lobby public.catudy_lobbies%rowtype;
  v_owner boolean := false;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  select *
  into v_lobby
  from public.catudy_lobbies
  where code = upper(trim(p_code))
    and status <> 'finished';

  if not found then
    raise exception 'lobby not found';
  end if;

  v_owner := v_lobby.owner_user_id = v_user_id;

  insert into public.catudy_lobby_members (
    lobby_id,
    user_id,
    display_name,
    pet_id,
    pet_name,
    equipped_pet_item_id,
    ready,
    owner,
    connected,
    break_vote,
    updated_at
  )
  values (
    v_lobby.id,
    v_user_id,
    coalesce(nullif(trim(p_display_name), ''), 'Guest Cat'),
    coalesce(nullif(trim(p_pet_id), ''), 'mochi'),
    coalesce(nullif(trim(p_pet_name), ''), 'White Cat'),
    p_equipped_pet_item_id,
    v_owner,
    v_owner,
    true,
    null,
    now()
  )
  on conflict (lobby_id, user_id) do update
  set
    display_name = excluded.display_name,
    pet_id = excluded.pet_id,
    pet_name = excluded.pet_name,
    equipped_pet_item_id = excluded.equipped_pet_item_id,
    connected = true,
    break_vote = null,
    updated_at = now();

  return v_lobby;
end;
$$;

create or replace function public.catudy_set_lobby_ready(
  p_lobby_id uuid,
  p_ready boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  update public.catudy_lobby_members
  set ready = coalesce(p_ready, false), connected = true, updated_at = now()
  where lobby_id = p_lobby_id
    and user_id = v_user_id;
  return found;
end;
$$;

create or replace function public.catudy_start_lobby(
  p_lobby_id uuid,
  p_category_id text,
  p_duration_minutes integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_updated_count integer := 0;
begin
  update public.catudy_lobbies
  set
    status = 'running',
    started_at = now(),
    category_id = coalesce(nullif(trim(p_category_id), ''), 'study'),
    duration_minutes = least(greatest(coalesce(p_duration_minutes, 25), 1), 240),
    paused_at = null,
    paused_seconds = 0,
    pause_reason = null,
    break_vote_round = 0,
    updated_at = now()
  where id = p_lobby_id
    and owner_user_id = v_user_id;
  get diagnostics v_updated_count = row_count;
  if v_updated_count = 0 then
    return false;
  end if;
  update public.catudy_lobby_members
  set break_vote = null, break_vote_updated_at = now(), updated_at = now()
  where lobby_id = p_lobby_id;
  return true;
end;
$$;

create or replace function public.catudy_pause_lobby(
  p_lobby_id uuid,
  p_reason text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_updated_count integer := 0;
begin
  update public.catudy_lobbies
  set
    paused_at = now(),
    pause_reason = case when p_reason = 'break' then 'break' else 'manual' end,
    updated_at = now()
  where id = p_lobby_id
    and owner_user_id = v_user_id
    and status = 'running';
  get diagnostics v_updated_count = row_count;
  if v_updated_count = 0 then
    return false;
  end if;
  update public.catudy_lobby_members
  set break_vote = null, break_vote_updated_at = now(), updated_at = now()
  where lobby_id = p_lobby_id;
  return true;
end;
$$;

create or replace function public.catudy_resume_lobby(
  p_lobby_id uuid,
  p_paused_seconds integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_updated_count integer := 0;
begin
  update public.catudy_lobbies
  set
    paused_at = null,
    paused_seconds = least(greatest(coalesce(p_paused_seconds, 0), 0), 2592000),
    pause_reason = null,
    updated_at = now()
  where id = p_lobby_id
    and owner_user_id = v_user_id
    and status = 'running';
  get diagnostics v_updated_count = row_count;
  if v_updated_count = 0 then
    return false;
  end if;
  update public.catudy_lobby_members
  set break_vote = null, break_vote_updated_at = now(), updated_at = now()
  where lobby_id = p_lobby_id;
  return true;
end;
$$;

create or replace function public.catudy_finish_lobby(p_lobby_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  update public.catudy_lobbies
  set status = 'finished', updated_at = now()
  where id = p_lobby_id
    and owner_user_id = v_user_id;
  return found;
end;
$$;

create or replace function public.catudy_leave_lobby(p_lobby_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  update public.catudy_lobby_members
  set connected = false, ready = false, break_vote = null, updated_at = now()
  where lobby_id = p_lobby_id
    and user_id = v_user_id;
  return found;
end;
$$;

revoke all on function public.catudy_create_lobby(text, text, text, text, text, text, integer) from public;
revoke all on function public.catudy_join_lobby(text, text, text, text, text) from public;
revoke all on function public.catudy_set_lobby_ready(uuid, boolean) from public;
revoke all on function public.catudy_start_lobby(uuid, text, integer) from public;
revoke all on function public.catudy_pause_lobby(uuid, text) from public;
revoke all on function public.catudy_resume_lobby(uuid, integer) from public;
revoke all on function public.catudy_finish_lobby(uuid) from public;
revoke all on function public.catudy_leave_lobby(uuid) from public;
grant execute on function public.catudy_create_lobby(text, text, text, text, text, text, integer),
  public.catudy_join_lobby(text, text, text, text, text),
  public.catudy_set_lobby_ready(uuid, boolean),
  public.catudy_start_lobby(uuid, text, integer),
  public.catudy_pause_lobby(uuid, text),
  public.catudy_resume_lobby(uuid, integer),
  public.catudy_finish_lobby(uuid),
  public.catudy_leave_lobby(uuid)
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
