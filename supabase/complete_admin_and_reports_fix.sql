-- ==============================================================================
-- CommuNEUcate: Complete Admin Access & RLS Fix
-- Run this in your Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. Ensure danieltelen14@gmail.com has an admin profile and approved status
insert into public.profiles (id, email, full_name, role, account_status)
select 
  id, 
  email, 
  coalesce(raw_user_meta_data ->> 'full_name', raw_user_meta_data ->> 'name', 'Daniel Telen'), 
  'admin', 
  'approved'
from auth.users
where lower(email) = lower('danieltelen14@gmail.com')
on conflict (id) do update
set role = 'admin',
    account_status = 'approved';

update public.profiles
set role = 'admin',
    account_status = 'approved'
where lower(email) = lower('danieltelen14@gmail.com');

-- 2. Allow admins with non-NEU emails (like gmail.com) to access the system
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

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

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;
revoke all on function public.is_neu_user() from public;
grant execute on function public.is_neu_user() to authenticated;

-- 3. Fix the infinite recursion on "reports" when approving/rejecting
create or replace function public.has_pending_claim_for_report(target_report_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.claims c
    where c.report_id = target_report_id
      and c.claimer_id = (select auth.uid())
      and c.status = 'pending'
  );
$$;

revoke all on function public.has_pending_claim_for_report(bigint) from public;
grant execute on function public.has_pending_claim_for_report(bigint) to authenticated;

create or replace function public.is_report_owner(target_report_id bigint, target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.reports r
    where r.id = target_report_id
      and r.reporter_id = target_user_id
  );
$$;

revoke all on function public.is_report_owner(bigint, uuid) from public;
grant execute on function public.is_report_owner(bigint, uuid) to authenticated;

drop policy if exists "Claimer flags report for review" on public.reports;
create policy "Claimer flags report for review" on public.reports
  for update to authenticated
  using (
    (select public.has_app_access())
    and status = 'unclaimed'
    and (select public.has_pending_claim_for_report(id))
  )
  with check (
    (select public.has_app_access())
    and status = 'pending_review'
    and (select public.has_pending_claim_for_report(id))
  );

drop policy if exists "Read related claims or admin" on public.claims;
create policy "Read related claims or admin" on public.claims
  for select to authenticated
  using ((select public.has_app_access()) and (
    claimer_id = (select auth.uid())
    or (select public.is_report_owner(report_id, (select auth.uid())))
    or (select public.is_admin())
  ));

-- 4. Confirm the admin status for danieltelen14@gmail.com
select email, role, account_status
from public.profiles
where lower(email) = lower('danieltelen14@gmail.com');
