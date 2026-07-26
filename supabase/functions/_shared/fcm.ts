// Shared helper: sends a push via the FCM HTTP v1 API using a Google
// service-account JWT. Deploy secrets with:
//   supabase secrets set FCM_SERVICE_ACCOUNT_JSON='<the whole JSON key>'
//   supabase secrets set FCM_PROJECT_ID='your-firebase-project-id'
//   supabase secrets set SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=...
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

async function getAccessToken(): Promise<string> {
  const saJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
  if (!saJson) throw new Error('FCM_SERVICE_ACCOUNT_JSON not configured');
  const sa: ServiceAccount = JSON.parse(saJson);

  const header = { alg: 'RS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const unsigned = `${enc(header)}.${enc(claim)}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  const jwt = `${unsigned}.${sigB64}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!json.access_token) throw new Error(`Failed to get access token: ${JSON.stringify(json)}`);
  return json.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

export function supabaseAdmin() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
}

export async function sendFcmToTokens(
  tokens: string[],
  notification: { title: string; body: string },
  data: Record<string, string>,
) {
  if (tokens.length === 0) return { sent: 0 };
  const projectId = Deno.env.get('FCM_PROJECT_ID');
  const accessToken = await getAccessToken();

  let sent = 0;
  // FCM HTTP v1 sends one message per request; fan out concurrently in
  // small batches to stay well under Edge Function CPU/time limits.
  const batchSize = 20;
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    await Promise.all(
      batch.map((token) =>
        fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token,
              notification,
              data,
              android: { priority: 'high' },
            },
          }),
        }).then(() => sent++),
      ),
    );
  }
  return { sent };
}
