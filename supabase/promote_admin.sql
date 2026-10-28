-- Run after danieltelen14@gmail.com has signed up and a row exists in public.profiles.
-- This grants admin privileges and approves the account.
update public.profiles
set role = 'admin',
    account_status = 'approved'
where lower(email) = lower('danieltelen14@gmail.com');

-- Confirm the account received admin access.
select email, role, account_status
from public.profiles
where lower(email) = lower('danieltelen14@gmail.com');

/* Previous admin target retained for reference:
-- Run after danieltelen56@gmail.com has been invited or signed up
-- and a row for the account exists in public.profiles.
update public.profiles
set role = 'admin',
    account_status = 'approved'
where lower(email) = lower('danieltelen56@gmail.com');
*/

-- Confirm the account received admin access.
select email, role, account_status
from public.profiles
where lower(email) = lower('danieltelen56@gmail.com');
