# TickBell

An invite-only, private community Android app for live options-trading
discussions over Google Meet — real-time "bell" trade alerts, session
scheduling, a recording library, charts, and full role-based admin controls.

Built with Flutter (Clean Architecture, Material 3, Riverpod) + Supabase
(Postgres, Auth, Realtime, Storage, Edge Functions) + Firebase Cloud
Messaging for push notifications.

> **This is a real, working codebase, not a demo.** Every screen, repository,
> and SQL policy in here does something — but you still need to complete the
> one-time setup below (Supabase project, Firebase project, Google OAuth
> client, keystore) before you have a signed APK you can put in front of
> real users. None of that can be skipped — they're external accounts only
> you can create.

---

## 1. Architecture at a glance

```
lib/
  core/                    # cross-cutting: theme, constants, errors, services
    services/
      supabase/            # Supabase client bootstrap
      fcm/                 # Firebase Cloud Messaging + local notifications
      google_auth/         # Google Sign-In -> Supabase federation
      secure_storage/      # Android Keystore-backed encrypted storage
  features/
    auth/                  # domain/data/presentation, Clean Architecture per feature
    invite/
    bell/                  # live trade alerts, realtime stream
    meet/                  # Google Meet session scheduling/joining
    recordings/
    charts/                # fl_chart, derived from bell price history
    admin/                 # invites, members, send-bell, schedule-session, announcements
    settings/
    profile/
    legal/                 # Privacy / Terms / Risk Disclosure + acceptance flow
    home/                  # bottom-nav shell, splash
  app.dart                 # MaterialApp, _AuthGate, named routes, biometric lock
  main.dart                # bootstrap: Firebase, Supabase, FCM

supabase/
  migrations/              # run in numeric order against your Supabase project
  functions/               # Edge Functions (Deno) for push fanout + account deletion

android/                   # standard Flutter Android project, Kotlin, AGP 8.5
```

Each feature follows `domain` (entities, repository interfaces) →
`data` (models, repository implementations hitting Supabase) →
`presentation` (Riverpod providers, screens, widgets). Errors flow as
`Either<Failure, T>` (via `dartz`) from repositories up to the UI, which
renders explicit loading/empty/error states — there's no silent failure
anywhere in the data layer.

---

## 2. Prerequisites

- Flutter 3.22+ (`flutter --version`)
- A Supabase project (free tier is fine to start)
- A Firebase project with Cloud Messaging enabled
- A Google Cloud project with an OAuth **Web** client ID
- Android Studio or the Android SDK command-line tools (for a release keystore)
- A Codemagic account (you mentioned you're using this to build the APK)

---

## 3. Supabase setup

1. Create a project at https://supabase.com — this app is already configured
   to use:
   ```
   SUPABASE_URL=https://xwdpvoqhyynxpfimexyw.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_cF9HPa8yprZxQD_2Sa43wg_9df3o46S
   ```
   These are already filled into `.env` for you. If this is **your own**
   Supabase project, double check these match Project Settings > API in
   your dashboard. The anon/publishable key is safe to ship in the app —
   it relies entirely on Row Level Security (RLS) for protection, which
   migration `002` sets up.

2. Run the migrations **in order** — open Supabase Dashboard > SQL Editor
   and paste/run each file under `supabase/migrations/`:
   ```
   001_core_schema.sql
   002_row_level_security.sql
   003_functions.sql
   004_triggers.sql
   005_storage_buckets.sql
   ```
   (`006_bootstrap_owner.sql` is instructions only — see step 5 below.)

3. Enable the `pg_net` extension if migration 001 doesn't auto-enable it:
   Dashboard > Database > Extensions > search `pg_net` > Enable.

4. Enable Google as an Auth provider: Dashboard > Authentication > Providers
   > Google > toggle on, and paste your **Web OAuth Client ID** (see §5)
   into the "Client IDs" field. You do NOT need the Google secret here
   since we sign in with `signInWithIdToken` from the native Google
   Sign-In SDK, not the redirect-based OAuth flow.

5. **Bootstrap your own owner account**: run the app once, sign in with
   Google (you'll land on the "Enter invite code" screen — that's
   expected, ignore it for now), then in SQL Editor run:
   ```sql
   update public.profiles set role = 'owner', is_active = true
   where email = 'you@example.com';
   ```
   Reopen the app — you'll now see the Admin Panel, from which you can
   generate invite codes for everyone else.

6. Deploy the Edge Functions (requires the Supabase CLI):
   ```bash
   supabase login
   supabase link --project-ref xwdpvoqhyynxpfimexyw
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat path/to/firebase-service-account.json)"
   supabase secrets set FCM_PROJECT_ID=your-firebase-project-id
   supabase secrets set EDGE_FUNCTION_SECRET=some-long-random-string
   supabase functions deploy notify-bell
   supabase functions deploy notify-announcement
   supabase functions deploy delete-account
   ```
   Then, back in SQL Editor, set the two settings the triggers read:
   ```sql
   alter database postgres set app.settings.edge_function_url = 'https://xwdpvoqhyynxpfimexyw.functions.supabase.co';
   alter database postgres set app.settings.edge_function_secret = 'the-same-long-random-string';
   ```

   > Push notifications won't fire until this step is done — everything
   > else in the app (bells list, sessions, charts, admin panel) works
   > without it, since that's all direct Postgres reads/writes.

---

## 4. Firebase (push notifications) setup

1. Create a project at https://console.firebase.google.com
2. Add an Android app with package name **`com.tickbell.app`**
3. Download `google-services.json` and place it at `android/app/google-services.json`
   (git-ignored — never commit this file)
4. Install the FlutterFire CLI and regenerate `lib/firebase_options.dart`
   with your real project values:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=your-firebase-project-id --platforms=android
   ```
5. Project Settings > Service Accounts > Generate new private key — this
   JSON is what you pass to `FCM_SERVICE_ACCOUNT_JSON` in §3.6 above.

---

## 5. Google Sign-In setup

1. In Google Cloud Console (same project as Firebase, or link one), go to
   **APIs & Services > Credentials > Create Credentials > OAuth client ID**.
2. Create **two** client IDs:
   - **Web application** — no redirect URIs needed. This is your
     `GOOGLE_SERVER_CLIENT_ID` (put it in `.env` and in Supabase's Google
     provider settings, per §3.4).
   - **Android** — package name `com.tickbell.app`, and the SHA-1
     fingerprint of both your debug keystore (`keytool -list -v -keystore
     ~/.android/debug.keystore`, password `android`) and your release
     keystore (§6).
3. Add the OAuth consent screen basics (app name "TickBell", support
   email) — internal/testing mode is fine while you're inviting a small
   private group.

---

## 6. Release signing (Android keystore)

```bash
keytool -genkey -v -keystore tickbell-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias tickbell
```

Copy `android/key.properties.example` to `android/key.properties` and fill
in the path/passwords. **Never commit `key.properties` or the `.jks` file**
— both are already in `.gitignore`.

---

## 7. Building with Codemagic

A ready-to-use `codemagic.yaml` is included at the repo root.

**Fastest path to a test APK (debug-signed, skip Play Store signing):**
1. Push this project to a GitHub/GitLab/Bitbucket repo, connect it in
   Codemagic.
2. Codemagic > App settings > Environment variables: add a group named
   `tickbell_secrets` with `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
   `GOOGLE_SERVER_CLIENT_ID` (values from §3/§5).
3. Either delete the `android_signing:` block from `codemagic.yaml` for a
   first test build (it'll fall back to debug signing per `build.gradle`),
   or follow the next step for a real release build.

**Full release build (Play Store-ready, properly signed):**
1. Codemagic > Team settings > Code signing identities > Android keystore
   → upload your `.jks` from §6, name the reference `tickbell_keystore`,
   matching the `android_signing:` group name in `codemagic.yaml`.
2. Trigger the `tickbell-android-release` workflow. Artifacts (`.apk` and
   `.aab`) appear under the build's Artifacts tab when it finishes.

**Building locally instead**, if you'd rather test on your own machine
first:
```bash
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xwdpvoqhyynxpfimexyw.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_cF9HPa8yprZxQD_2Sa43wg_9df3o46S \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id
```
The `.apk` lands at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 8. Roles & permissions

| Role       | Bells (send) | Sessions (schedule) | Invites (create) | Manage members | Announcements |
|------------|:---:|:---:|:---:|:---:|:---:|
| `member`   | ❌ | ❌ | ❌ | ❌ | ❌ |
| `moderator`| ✅ | ✅ | ❌ | ❌ | ❌ |
| `admin`    | ✅ | ✅ | ✅ | ✅ | ✅ |
| `owner`    | ✅ | ✅ | ✅ | ✅ | ✅ |

All of the above is enforced **twice**: once in the UI (hiding buttons
non-privileged users shouldn't see) and once in Postgres via Row Level
Security (`supabase/migrations/002_row_level_security.sql`) and
`SECURITY DEFINER` functions — so a rooted/patched client can't bypass
permissions by calling the API directly.

---

## 9. What's genuinely production-grade here vs. what to review before launch

**Solid as-is:**
- Clean Architecture separation, explicit error/loading/empty states throughout
- RLS-enforced, invite-gated, role-based access control at the database layer
- Atomic invite redemption (row-locked, race-condition-safe)
- Encrypted local storage (Android Keystore-backed) for the biometric-lock flag
- ProGuard/R8 minification, no debug-signed release builds by default

**You must review/replace before a public Play Store release:**
- The Privacy Policy / Terms / Risk Disclosure text in
  `lib/features/legal/legal_content.dart` is structurally complete but
  needs a lawyer's pass, given this app facilitates financial discussion.
- App icon/splash are placeholder generated glyphs — swap
  `assets/icons/app_icon.png` and `assets/images/splash_logo.png` for real
  branded art, then re-run:
  ```bash
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
  ```
- Play Store requires a privacy policy URL and a Data Safety form — host
  the legal pages somewhere public (or use an in-app-only policy plus a
  simple static page) and fill in the Play Console Data Safety section
  honestly based on what's actually collected (see §3, `profiles` table).

---

## 10. Known follow-ups (not yet built)

- Deep link handling for `tickbell://invite/<code>` is declared in the
  manifest but not yet wired to auto-fill the redeem-invite screen —
  currently invite codes are shared/entered manually.
- Recording upload flow is a manual admin step (attach a Storage URL to a
  session) rather than an in-app "start recording" control, since Google
  Meet recording itself happens inside Meet, not inside TickBell.
