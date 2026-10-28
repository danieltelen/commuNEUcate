-- Restore access for a confirmed administrator who signs in with a non-NEU email.
-- Regular user access remains restricted to confirmed @neu.edu.ph accounts.
-- This does not modify profile roles or approval statuses.

create or replace function public.is_neu_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
      select 1 from auth.users u
      where u.id = (select auth.uid())
        and u.email_confirmed_at is not null
    )
    and (
      lower(coalesce(auth.jwt() ->> 'email', '')) ~ '^[^@]+@neu\.edu\.ph$'
      or (select public.is_admin())
    );
$$;
