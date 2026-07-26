-- =====================================================================
-- TickBell — Bootstrap: promote the first owner
-- Run this ONCE, manually, after your own account has signed in via
-- Google at least once (so a `profiles` row exists for you).
-- =====================================================================

-- 1. Find your user id (replace with your email):
--    select id, email from public.profiles where email = 'you@example.com';

-- 2. Promote yourself to owner and activate immediately (bypassing the
--    invite requirement, since owners bootstrap the whole invite chain):
--    update public.profiles
--      set role = 'owner', is_active = true
--      where email = 'you@example.com';

-- From there, use the in-app Admin Panel > Manage Invites to generate
-- codes for your first admins/members.
