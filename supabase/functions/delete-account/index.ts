// supabase/functions/delete-account/index.ts
// Called from Settings > Delete Account. Runs with the service-role key
// (never exposed client-side) to remove the profile row and the auth.users
// entry together, so no orphaned auth account is left behind.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const jwt = authHeader.replace('Bearer ', '');

    // Verify the caller's JWT using the anon client, then act with the
    // service-role client so the caller can only ever delete themselves.
    const anonClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } = await anonClient.auth.getUser(jwt);
    if (userError || !userData?.user) {
      return new Response('Unauthorized', { status: 401 });
    }
    const userId = userData.user.id;

    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    await adminClient.from('device_tokens').delete().eq('user_id', userId);
    await adminClient.from('profiles').delete().eq('id', userId);
    const { error: authDeleteError } = await adminClient.auth.admin.deleteUser(userId);
    if (authDeleteError) throw authDeleteError;

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
