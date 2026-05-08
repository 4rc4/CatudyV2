create table if not exists public.catudy_friend_requests (
  id uuid primary key default gen_random_uuid(),
  requester_user_id uuid not null references auth.users(id) on delete cascade,
  receiver_user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_user_id <> receiver_user_id)
);

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

alter table public.catudy_friend_requests enable row level security;
alter table public.catudy_friends enable row level security;

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
  using (auth.uid() = owner_user_id);

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
