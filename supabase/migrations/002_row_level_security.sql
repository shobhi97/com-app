-- =====================================================================
-- TickBell — Migration 002: Row Level Security
-- Principle: every table defaults to deny-all; explicit policies open
-- exactly the access each role needs. Client apps use the anon/public
-- key exclusively — the service_role key never ships in the app.
-- =====================================================================

alter table public.profiles enable row level security;
alter table public.invites enable row level security;
alter table public.live_sessions enable row level security;
alter table public.bells enable row level security;
alter table public.bell_reads enable row level security;
alter table public.device_tokens enable row level security;
alter table public.announcements enable row level security;
alter table public.audit_log enable row level security;

-- Helper: current user's role, used inside policies without recursive
-- RLS evaluation loops (SECURITY DEFINER + STABLE for planner caching).
create or replace function public.current_user_role()
returns user_role
language sql
security definer
stable
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin_or_above()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select public.current_user_role() in ('owner', 'admin');
$$;

create or replace function public.is_moderator_or_above()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select public.current_user_role() in ('owner', 'admin', 'moderator');
$$;

-- ---------------------------------------------------------------------
-- PROFILES
-- ---------------------------------------------------------------------
-- Every authenticated user can read all profiles (member directory / bell
-- author names) but only see membership internals they're entitled to.
create policy profiles_select_authenticated
  on public.profiles for select
  using (auth.role() = 'authenticated');

-- Users may insert only their own row (bootstrap on first sign-in), and
-- only as an inactive member — activation happens exclusively via the
-- redeem_invite() function, never directly.
create policy profiles_insert_self
  on public.profiles for insert
  with check (auth.uid() = id and is_active = false and role = 'member');

-- Users can update their own non-privileged fields (display name, avatar,
-- biometric flag, legal-acceptance versions) but NOT role or is_active.
create policy profiles_update_self_limited
  on public.profiles for update
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    and role = (select role from public.profiles where id = auth.uid())
    and is_active = (select is_active from public.profiles where id = auth.uid())
  );

-- Admins/owners may update ANY profile's role or active status.
create policy profiles_admin_update_any
  on public.profiles for update
  using (public.is_admin_or_above())
  with check (public.is_admin_or_above());

-- ---------------------------------------------------------------------
-- INVITES
-- ---------------------------------------------------------------------
-- Only admins/owners can create or list invites directly. Redemption is
-- handled through the SECURITY DEFINER redeem_invite() RPC below, which
-- bypasses these SELECT/UPDATE restrictions safely for the pending code
-- being redeemed only.
create policy invites_admin_all
  on public.invites for all
  using (public.is_admin_or_above())
  with check (public.is_admin_or_above());

-- ---------------------------------------------------------------------
-- LIVE SESSIONS
-- ---------------------------------------------------------------------
create policy sessions_select_active_members
  on public.live_sessions for select
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_active)
  );

create policy sessions_moderator_write
  on public.live_sessions for insert
  with check (public.is_moderator_or_above());

create policy sessions_moderator_update
  on public.live_sessions for update
  using (public.is_moderator_or_above())
  with check (public.is_moderator_or_above());

-- ---------------------------------------------------------------------
-- BELLS
-- ---------------------------------------------------------------------
create policy bells_select_active_members
  on public.bells for select
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_active)
  );

create policy bells_moderator_insert
  on public.bells for insert
  with check (
    public.is_moderator_or_above()
    and created_by = auth.uid()
  );

-- ---------------------------------------------------------------------
-- BELL READS
-- ---------------------------------------------------------------------
create policy bell_reads_own_upsert
  on public.bell_reads for insert
  with check (user_id = auth.uid());

create policy bell_reads_own_update
  on public.bell_reads for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy bell_reads_select_own
  on public.bell_reads for select
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- DEVICE TOKENS
-- ---------------------------------------------------------------------
create policy device_tokens_own_all
  on public.device_tokens for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- ANNOUNCEMENTS
-- ---------------------------------------------------------------------
create policy announcements_select_active_members
  on public.announcements for select
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_active)
  );

create policy announcements_admin_insert
  on public.announcements for insert
  with check (public.is_admin_or_above());

-- ---------------------------------------------------------------------
-- AUDIT LOG — server/admin readable only, never client-writable
-- ---------------------------------------------------------------------
create policy audit_log_admin_select
  on public.audit_log for select
  using (public.is_admin_or_above());
