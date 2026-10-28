-- Apply this in Supabase SQL Editor if setup.sql has already been run.
-- Makes the public item list obey the caller's RLS permissions while still
-- allowing anonymous browsing of published items through safe columns only.

alter view public.public_reports
  set (security_invoker = true);

drop policy if exists "Read publicly listed reports" on public.reports;
create policy "Read publicly listed reports" on public.reports
  for select to anon
  using (status in ('unclaimed', 'claimed'));

revoke all privileges on table public.reports from anon;
grant select (
  id, item_name, category, location_found, date_found, description,
  tags, security_question, image_url, status, created_at
) on table public.reports to anon;

grant select on public.public_reports to anon, authenticated;
