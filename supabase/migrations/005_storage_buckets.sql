-- =====================================================================
-- TickBell — Migration 005: Storage buckets
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('recordings', 'recordings', false, 2147483648, array['video/mp4', 'video/webm'])
on conflict (id) do nothing;

-- Avatars: publicly readable, but only the owning user can write to their
-- own folder (path convention: {user_id}/avatar.jpg).
create policy avatars_public_read
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy avatars_owner_write
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy avatars_owner_update
  on storage.objects for update
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- Recordings: private bucket. Only active members can read (via signed
-- URLs generated server-side); only moderators+ can upload.
create policy recordings_active_member_read
  on storage.objects for select
  using (
    bucket_id = 'recordings'
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_active)
  );

create policy recordings_moderator_write
  on storage.objects for insert
  with check (bucket_id = 'recordings' and public.is_moderator_or_above());
