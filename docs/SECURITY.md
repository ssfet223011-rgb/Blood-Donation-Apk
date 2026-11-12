# BloodBond Bangladesh — Security & Privacy Architecture

## 1. Threat Model & Privacy Principles

Blood donation applications handle sensitive personal data, physical health information, and real-time physical locations. An insecure blood donation app exposes users to:
- Location tracking / stalking of voluntary donors.
- Spam, harassment, or commercial blood broker targeting via leaked mobile numbers.
- Forged donor credentials or false emergency blood solicitations.

BloodBond Bangladesh implements a **Zero Trust Client** model:

1. **Client-Side Permission Blindness**: The client application is never trusted for authorization checks. All role validations, donation verification, and status changes are verified inside PostgreSQL RLS and security definer RPCs.
2. **Never Expose Supabase Service Role Key**: The Flutter client application is built strictly with the `anon` key. Administrative operations are performed through authenticated RPCs or the isolated Admin Panel.
3. **No Direct Phone Number Exposure**: Blood seeker accounts cannot read a donor's mobile number directly from tables. Access is strictly granted via the `contact_requests` consent workflow.
4. **Geographic Fuzzing / Obfuscation**: The PostGIS RPC calculates distance server-side and outputs jittered coordinates (`approx_latitude`, `approx_longitude`) rounded to approximately 1 square kilometer.
5. **No Medical Eligibility Guarantees**: The platform manages voluntary availability, not clinical clearance. Medical screening occurs at certified blood banks and hospitals prior to phlebotomy.

---

## 2. Row Level Security (RLS) Specification

All 20 tables in the public schema have Row Level Security enabled. Sample policies:

### Profiles
```sql
-- Users can only modify their own profile data
create policy "Profiles: users can update own profile"
    on public.profiles for update
    to authenticated
    using (auth.uid() = id);
```

### Donor Locations
```sql
-- Donors can only view and update their own exact GPS point
create policy "DonorLocations: donors manage their own location"
    on public.donor_locations for all
    to authenticated
    using (donor_id in (select id from public.donor_profiles where user_id = auth.uid()));
```

### Contact Requests Handshake
```sql
-- Donors can only approve requests addressed to them
create policy "ContactRequests: donors can respond to requests"
    on public.contact_requests for update
    to authenticated
    using (donor_id in (select id from public.donor_profiles where user_id = auth.uid()) or public.is_admin_or_moderator(auth.uid()));
```

---

## 3. Cryptographic Token & Local Storage

On mobile devices, sensitive authentication session tokens are stored using `flutter_secure_storage`:
- Android: Encrypted using Android KeyStore + AES cipher with KeyStore-backed master key.
- iOS: Keychain Services with `kSecAttrAccessibleAfterFirstUnlock`.
- Offline storage caches only non-sensitive data (e.g. Bangladesh administrative hierarchy, FAQs, app branding).
