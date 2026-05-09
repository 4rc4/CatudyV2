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
  using (
    auth.uid() = requester_user_id
    or auth.uid() = receiver_user_id
  );

drop policy if exists "users can create their friend requests"
  on public.catudy_friend_requests;
create policy "users can create their friend requests"
  on public.catudy_friend_requests
  for insert
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
  using (auth.uid() = owner_user_id);

drop policy if exists "users can add their accepted friends"
  on public.catudy_friends;
create policy "users can add their accepted friends"
  on public.catudy_friends
  for insert
  with check (auth.uid() = owner_user_id);

drop policy if exists "users can remove their friends"
  on public.catudy_friends;
create policy "users can remove their friends"
  on public.catudy_friends
  for delete
  using (auth.uid() = owner_user_id or auth.uid() = friend_user_id);

drop policy if exists "blocked users are visible to owner"
  on public.catudy_blocked_users;
create policy "blocked users are visible to owner"
  on public.catudy_blocked_users
  for select
  using (auth.uid() = owner_user_id);

drop policy if exists "users can create blocked users"
  on public.catudy_blocked_users;
create policy "users can create blocked users"
  on public.catudy_blocked_users
  for insert
  with check (auth.uid() = owner_user_id);

drop policy if exists "users can remove blocked users"
  on public.catudy_blocked_users;
create policy "users can remove blocked users"
  on public.catudy_blocked_users
  for delete
  using (auth.uid() = owner_user_id);

drop policy if exists "users can report profiles"
  on public.catudy_profile_reports;
create policy "users can report profiles"
  on public.catudy_profile_reports
  for insert
  with check (auth.uid() = reporter_user_id);

drop policy if exists "users can view their own reports"
  on public.catudy_profile_reports;
create policy "users can view their own reports"
  on public.catudy_profile_reports
  for select
  using (auth.uid() = reporter_user_id);

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
  elsif new.status = 'rejected' and old.status = 'pending' then
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

do $$
begin
  alter publication supabase_realtime add table public.catudy_friend_requests;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.catudy_friends;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.catudy_blocked_users;
exception
  when duplicate_object then null;
end $$;
