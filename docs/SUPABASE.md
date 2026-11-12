# BloodBond Bangladesh — Supabase Backend Guide

## 1. Supabase Services Used

1. **Supabase Auth**:
   - Phone Number OTP (using Twilio or local Bangladesh SMS gateways e.g., Reve Systems, SSL Wireless via Supabase Auth Webhooks).
   - Email and Password with secure verification links.
   - Google Sign-In for streamlined onboarding.
2. **Supabase PostgreSQL & PostGIS**:
   - High performance spatial querying for nearby donor discovery.
   - Database functions, triggers, and scheduled cron jobs.
3. **Supabase Storage**:
   - Secure buckets for profile photos, campaign graphics, and verification slips.
4. **Supabase Edge Functions**:
   - Serverless Deno/TypeScript handlers for background matching, FCM push notifications, and cryptographic donor ID verification.
5. **Supabase Realtime**:
   - Instant broadcast of emergency blood requests and in-app notifications.

---

## 2. Environment Variables

Create a `.env` file in the root directory (never commit to version control):

```env
# Client-side Safe (Used in Flutter App)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...

# Server-side Only (Used in Edge Functions and CI/CD)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...

# Push Notifications
FIREBASE_SERVER_KEY=your-firebase-server-key-or-fcm-v1-json
```

---

## 3. Applying Migrations

Run migrations using the Supabase CLI:

```bash
# Login to Supabase
supabase login

# Link your local project to Supabase project
supabase link --project-ref your-project-id

# Push migrations
supabase db push
```

Alternatively, you can copy the SQL files from `supabase/migrations/` in sequential order into the Supabase SQL Editor:
1. `20261112000001_initial_schema.sql`
2. `20261112000002_postgis_location_rpcs.sql`
3. `20261112000003_triggers_and_automation.sql`
4. `20261112000004_rls_policies.sql`
5. `20261112000005_storage_buckets.sql`
6. `20261112000006_seed_data.sql`
