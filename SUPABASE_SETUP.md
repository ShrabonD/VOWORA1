# Supabase Setup Guide - VOWORA

This guide details the complete configuration required to connect **VOWORA** to your live Supabase project.

---

## Step 1: Create a Supabase Project
1. Go to [https://supabase.com](https://supabase.com) and log in or create an account.
2. Click **New Project**, enter a project name (e.g., `vowora-wedding-planner`), set a strong database password, and select your region.

---

## Step 2: Retrieve Supabase URL & Anon Key
1. In your Supabase Dashboard, navigate to **Project Settings** (gear icon) -> **API**.
2. Copy the **Project URL** and the **`anon` public key**.

---

## Step 3: Insert Credentials into Vowora Code
Open `lib/core/constants/vowora_constants.dart` and replace the placeholder values:

```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-public-key-here';
```

---

## Step 4: Run SQL Migration & Enable Row Level Security (RLS)
1. Open your Supabase Dashboard -> **SQL Editor**.
2. Click **New Query**, paste the contents of `supabase_schema.sql` (found in the root directory).
3. Click **Run**. This will automatically create:
   - `profiles`
   - `wedding_profiles`
   - `budget_items`
   - `guests`
   - `vendors`
   - `checklist_tasks`
   - `timeline_events`
   - Automated `on_auth_user_created` trigger for profile initialization.

### Birthday booking schema
The Birthday module uses separate tables and is not created by `supabase_schema.sql`.
In the SQL Editor, run `supabase_birthday_schema.sql` after the main schema. For an
existing installation, apply `supabase_birthday_payment_migration.sql` after the
Birthday schema to add partial-payment fields and transaction idempotency. These
scripts create the Birthday tables only when absent; they do not create duplicate
tables. If PostgREST still reports `PGRST205`, refresh the schema cache from the
Supabase Dashboard or run `NOTIFY pgrst, 'reload schema';` in the SQL Editor.

Payment table writes are restricted to trusted server-side code. Do not grant the
Flutter client direct payment or booking-status writes. A production checkout also
requires a deployed Edge Function or equivalent backend configured with a
Bangladesh-compatible gateway's merchant credentials and verified callback flow.

---

## Step 5: Enable Email / Password Authentication
1. Go to **Authentication** -> **Providers** -> **Email**.
2. Turn ON **Enable Email provider**.
3. (Optional) Disable "Confirm email" if you want instant registration without waiting for email verification during testing.

---

## Step 6: Configure Google OAuth
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create OAuth 2.0 Credentials (Client ID and Client Secret).
3. Set Authorized Redirect URI in Google Cloud to:
   `https://<YOUR-SUPABASE-PROJECT-ID>.supabase.co/auth/v1/callback`
4. In Supabase Dashboard -> **Authentication** -> **Providers** -> **Google**:
   - Toggle ON Google Provider.
   - Enter your **Client ID** and **Client Secret**.

---

## Step 7: Configure Apple OAuth
1. Create a Services ID and Private Key in your [Apple Developer Portal](https://developer.apple.com/).
2. Configure Return URL: `https://<YOUR-SUPABASE-PROJECT-ID>.supabase.co/auth/v1/callback`
3. In Supabase Dashboard -> **Authentication** -> **Providers** -> **Apple**:
   - Toggle ON Apple Provider and fill in Service ID, Team ID, Key ID, and Secret Key.

---

## Step 8: Configure Facebook OAuth
1. Go to [Meta for Developers](https://developers.facebook.com/).
2. Create an App -> Add Facebook Login product.
3. Add Valid OAuth Redirect URI: `https://<YOUR-SUPABASE-PROJECT-ID>.supabase.co/auth/v1/callback`
4. In Supabase Dashboard -> **Authentication** -> **Providers** -> **Facebook**:
   - Toggle ON Facebook Provider and fill in App ID and App Secret.

---

## Step 9: Configure Supabase Storage
1. Go to **Storage** in Supabase Dashboard.
2. Click **New Bucket**, name it `avatars`, and set it to **Public**.
3. Add RLS policy allowing authenticated users to upload images into `avatars`.

---

## Step 10: Run the Vowora Application
Run the app using:
```bash
flutter run
```
If OAuth credentials are not configured yet, VOWORA automatically provides user-friendly notification popups without crashing. Email/password authentication and offline guest mode work out of the box!
