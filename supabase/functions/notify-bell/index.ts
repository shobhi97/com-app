// supabase/functions/notify-bell/index.ts
// Invoked by the `trg_notify_bell_subscribers` DB trigger whenever a new
// row is inserted into `bells`. Fetches every device token and sends a
// high-priority FCM push tagged type=bell so the client shows it on the
// dedicated "Bell Alerts" Android notification channel.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { supabaseAdmin, sendFcmToTokens } from '../_shared/fcm.ts';

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization');
    const expected = `Bearer ${Deno.env.get('EDGE_FUNCTION_SECRET')}`;
    if (authHeader !== expected) {
      return new Response('Unauthorized', { status: 401 });
    }

    const payload = await req.json();
    const { instrument, type, priority, message } = payload;

    const supabase = supabaseAdmin();
    const { data: tokens, error } = await supabase.from('device_tokens').select('fcm_token');
    if (error) throw error;

    const tokenList = (tokens ?? []).map((t: { fcm_token: string }) => t.fcm_token);

    const title = `🔔 ${String(type).toUpperCase()} — ${instrument}`;
    const result = await sendFcmToTokens(
      tokenList,
      { title, body: message || 'New bell in the room' },
      { type: 'bell', priority: String(priority) },
    );

    return new Response(JSON.stringify({ ok: true, ...result }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
