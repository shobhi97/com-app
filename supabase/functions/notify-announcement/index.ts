// supabase/functions/notify-announcement/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { supabaseAdmin, sendFcmToTokens } from '../_shared/fcm.ts';

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization');
    const expected = `Bearer ${Deno.env.get('EDGE_FUNCTION_SECRET')}`;
    if (authHeader !== expected) {
      return new Response('Unauthorized', { status: 401 });
    }

    const { title, body } = await req.json();

    const supabase = supabaseAdmin();
    const { data: tokens, error } = await supabase.from('device_tokens').select('fcm_token');
    if (error) throw error;

    const tokenList = (tokens ?? []).map((t: { fcm_token: string }) => t.fcm_token);
    const result = await sendFcmToTokens(tokenList, { title, body }, { type: 'announcement' });

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
