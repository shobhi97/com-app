-- =====================================================================
-- TickBell — Migration 004: Triggers
-- Fires an async HTTP call (via pg_net) to a Supabase Edge Function on
-- every new bell/announcement, which fans the push out over FCM HTTP v1.
-- Keeping this server-side means the FCM service-account key never has
-- to touch the client app.
-- =====================================================================

-- Set these two via: alter database postgres set app.edge_function_base_url = '...';
-- or, simpler, hardcode your project's function URL below after deploying.
create or replace function public.notify_bell_subscribers()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform net.http_post(
    url := current_setting('app.settings.edge_function_url', true) || '/notify-bell',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.edge_function_secret', true)
    ),
    body := jsonb_build_object(
      'bell_id', NEW.id,
      'instrument', NEW.instrument,
      'type', NEW.type,
      'priority', NEW.priority,
      'message', NEW.message
    )
  );
  return NEW;
end;
$$;

create trigger trg_notify_bell_subscribers
  after insert on public.bells
  for each row execute function public.notify_bell_subscribers();

create or replace function public.notify_announcement_subscribers()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform net.http_post(
    url := current_setting('app.settings.edge_function_url', true) || '/notify-announcement',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.edge_function_secret', true)
    ),
    body := jsonb_build_object('title', NEW.title, 'body', NEW.body)
  );
  return NEW;
end;
$$;

create trigger trg_notify_announcement_subscribers
  after insert on public.announcements
  for each row execute function public.notify_announcement_subscribers();

-- Keep profiles.last_seen_at fresh whenever a client touches its own row
-- via an explicit RPC call (see app: called on app resume).
create or replace function public.touch_last_seen()
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles set last_seen_at = now() where id = auth.uid();
$$;
