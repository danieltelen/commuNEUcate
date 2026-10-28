-- Fix reports <-> claims RLS recursion on existing Supabase projects.
-- Run this once in Supabase SQL Editor.

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
