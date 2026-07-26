-- =====================================================================
-- TickBell — Migration 001: Core schema
-- Run in order: 001, 002 (RLS), 003 (functions), 004 (triggers), 005 (seed)
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists pg_net; -- used by triggers to call Edge Functions

-- ---------------------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------------------
create type user_role as enum ('owner', 'admin', 'moderator', 'member');
create type invite_status as enum ('pending', 'redeemed', 'expired', 'revoked');
create type bell_type as enum ('buy', 'sell', 'exit', 'adjust', 'alert');
create type bell_priority as enum ('normal', 'high', 'urgent');
create type session_status as enum ('scheduled', 'live', 'ended', 'cancelled');

-- ---------------------------------------------------------------------
-- PROFILES — mirrors auth.users, extended with app-specific fields
-- ---------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null default '',
  avatar_url text,
  role user_role not null default 'member',
  is_active boolean not null default false, -- flips true only on invite redemption
  invited_by uuid references public.profiles(id) on delete set null,
  privacy_policy_accepted_version int,
  terms_accepted_version int,
  risk_disclosure_accepted_version int,
  biometric_lock_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz
);

create index idx_profiles_role on public.profiles(role);
create index idx_profiles_is_active on public.profiles(is_active);

-- ---------------------------------------------------------------------
-- INVITES
-- ---------------------------------------------------------------------
create table public.invites (
  id uuid primary key default uuid_generate_v4(),
  code text not null unique,
  created_by uuid not null references public.profiles(id) on delete cascade,
  redeemed_by uuid references public.profiles(id) on delete set null,
  status invite_status not null default 'pending',
  note text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  redeemed_at timestamptz
);

create index idx_invites_code on public.invites(code);
create index idx_invites_status on public.invites(status);

-- ---------------------------------------------------------------------
-- LIVE SESSIONS (Google Meet rooms)
-- ---------------------------------------------------------------------
create table public.live_sessions (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  description text,
  meet_link text not null,
  host_id uuid not null references public.profiles(id) on delete cascade,
  scheduled_start timestamptz not null,
  actual_start timestamptz,
  actual_end timestamptz,
  status session_status not null default 'scheduled',
  recording_url text,
  created_at timestamptz not null default now()
);

create index idx_sessions_status on public.live_sessions(status);
create index idx_sessions_scheduled_start on public.live_sessions(scheduled_start);

-- ---------------------------------------------------------------------
-- BELLS (trade alerts)
-- ---------------------------------------------------------------------
create table public.bells (
  id uuid primary key default uuid_generate_v4(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  type bell_type not null default 'alert',
  priority bell_priority not null default 'normal',
  instrument text not null,
  price numeric(12,2),
  target_price numeric(12,2),
  stop_loss numeric(12,2),
  message text not null default '',
  session_id uuid references public.live_sessions(id) on delete set null,
  created_at timestamptz not null default now()
);

create index idx_bells_created_at on public.bells(created_at desc);
create index idx_bells_instrument on public.bells(instrument);

-- ---------------------------------------------------------------------
-- BELL READ RECEIPTS
-- ---------------------------------------------------------------------
create table public.bell_reads (
  bell_id uuid not null references public.bells(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (bell_id, user_id)
);

-- ---------------------------------------------------------------------
-- DEVICE TOKENS (FCM)
-- ---------------------------------------------------------------------
create table public.device_tokens (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'android',
  updated_at timestamptz not null default now()
);

create index idx_device_tokens_user on public.device_tokens(user_id);

-- ---------------------------------------------------------------------
-- ANNOUNCEMENTS (general, non-bell broadcasts)
-- ---------------------------------------------------------------------
create table public.announcements (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  body text not null,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- AUDIT LOG (admin actions — role changes, deactivations, invite revokes)
-- ---------------------------------------------------------------------
create table public.audit_log (
  id uuid primary key default uuid_generate_v4(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  target_table text not null,
  target_id text,
  detail jsonb,
  created_at timestamptz not null default now()
);
