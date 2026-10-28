-- Run once in Supabase SQL Editor to enable automatic approval for Google sign-ins.
-- Google accounts are approved when created; email/password accounts stay pending.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role, account_status)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    'user',
    case
      when new.raw_app_meta_data ->> 'provider' = 'google' then 'approved'
      else 'pending'
    end
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(public.profiles.full_name, excluded.full_name);
  return new;
end;
$$;

update public.profiles p
set account_status = 'approved'
from auth.users u
where p.id = u.id
  and p.role = 'user'
  and p.account_status = 'pending'
  and u.raw_app_meta_data ->> 'provider' = 'google';
