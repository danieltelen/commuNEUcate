-- ==============================================================================
-- Fix reports <-> claims RLS recursion on Supabase
-- Run this once in your Supabase project's SQL Editor (Dashboard -> SQL Editor)
-- ==============================================================================

-- 1. Helper to check pending claims without triggering claims RLS
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

-- 2. Helper to check report ownership without triggering reports RLS
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

-- 3. Replace update policy on public.reports using the security definer function
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

-- 4. Replace select policy on public.claims using the security definer function
drop policy if exists "Read related claims or admin" on public.claims;
create policy "Read related claims or admin" on public.claims
  for select to authenticated
  using ((select public.has_app_access()) and (
    claimer_id = (select auth.uid())
    or (select public.is_report_owner(report_id, (select auth.uid())))
    or (select public.is_admin())
  ));
