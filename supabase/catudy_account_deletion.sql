-- Run this in the Supabase SQL Editor if the app says account deletion is not
-- ready on the server. It is also included in catudy_complete.sql.

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
grant execute on function public.catudy_delete_current_user() to authenticated;
