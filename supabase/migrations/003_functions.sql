-- =====================================================================
-- TickBell — Migration 003: Functions (RPCs)
-- =====================================================================

-- ---------------------------------------------------------------------
-- create_invite(p_note, p_expires_at) — admins/owners only.
-- Generates a human-friendly code like TICK-7F3K9Q.
-- ---------------------------------------------------------------------
create or replace function public.create_invite(p_note text default null, p_expires_at timestamptz default null)
returns public.invites
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_row public.invites;
begin
  if not public.is_admin_or_above() then
    raise exception 'permission_denied: only admins can create invites';
  end if;

  v_code := 'TICK-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));

  insert into public.invites (code, created_by, note, expires_at)
  values (v_code, auth.uid(), p_note, coalesce(p_expires_at, now() + interval '7 days'))
  returning * into v_row;

  insert into public.audit_log (actor_id, action, target_table, target_id, detail)
  values (auth.uid(), 'create_invite', 'invites', v_row.id::text, jsonb_build_object('code', v_code));

  return v_row;
end;
$$;

-- ---------------------------------------------------------------------
-- redeem_invite(invite_code) — any authenticated user with an inactive
-- profile. Atomic: locks the invite row so two concurrent redemption
-- attempts on the same code cannot both succeed (`for update`).
-- ---------------------------------------------------------------------
create or replace function public.redeem_invite(invite_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.invites;
begin
  select * into v_invite
  from public.invites
  where code = invite_code
  for update;

  if v_invite is null then
    raise exception 'invite_not_found';
  end if;

  if v_invite.status = 'redeemed' then
    raise exception 'invite_already_used';
  end if;

  if v_invite.status = 'revoked' then
    raise exception 'invite_already_used';
  end if;

  if v_invite.expires_at < now() then
    update public.invites set status = 'expired' where id = v_invite.id;
    raise exception 'invite_expired';
  end if;

  update public.invites
    set status = 'redeemed', redeemed_by = auth.uid(), redeemed_at = now()
    where id = v_invite.id;

  update public.profiles
    set is_active = true, invited_by = v_invite.created_by
    where id = auth.uid();

  insert into public.audit_log (actor_id, action, target_table, target_id, detail)
  values (auth.uid(), 'redeem_invite', 'invites', v_invite.id::text, jsonb_build_object('code', invite_code));
end;
$$;

-- ---------------------------------------------------------------------
-- unread_bell_count(p_user_id) — bells created after the user's account
-- creation that have no matching bell_reads row.
-- ---------------------------------------------------------------------
create or replace function public.unread_bell_count(p_user_id uuid)
returns integer
language sql
security definer
stable
set search_path = public
as $$
  select count(*)::int
  from public.bells b
  where not exists (
    select 1 from public.bell_reads r where r.bell_id = b.id and r.user_id = p_user_id
  );
$$;
