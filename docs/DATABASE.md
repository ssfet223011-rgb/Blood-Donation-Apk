# BloodBond Bangladesh — Database & PostGIS Architecture

## 1. PostGIS Spatial Modeling

The database uses PostgreSQL with the official PostGIS extension enabled:

```sql
create extension if not exists postgis;
```

All donor geographical coordinates are stored in the `donor_locations` table as a spherical geometry point (SRID 4326):

```sql
geom geometry(Point, 4326)
```

Spatial queries use the high-performance GIST index:

```sql
create index idx_donor_locations_geom on public.donor_locations using gist(geom);
```

### Privacy Safe Coordinate Jittering

Raw donor coordinates are only accessible by the donor themselves or central platform administrators. During nearby donor discovery, the `search_nearby_donors` RPC computes distances using `ST_DistanceSphere` on the server and returns:

- `distance_km`: Exact distance in kilometers from the search origin.
- `approx_latitude`: Obfuscated coordinate rounded to 2 decimal places (~1.1 km resolution).
- `approx_longitude`: Obfuscated coordinate.

---

## 2. Core Tables and Relations

1. `profiles`: Core user profile linked to Supabase Auth (`auth.users.id`).
2. `user_roles`: Multi-role mapping supporting `public`, `registered_user`, `donor`, `blood_seeker`, `volunteer`, `organization`, `moderator`, `admin`, `super_admin`.
3. `donor_profiles`: Specialized profile storing blood group, verified donations, verification badge, and cooldown availability status.
4. `donor_locations`: PostGIS coordinates with Division, District, Upazila, and Thana.
5. `donations`: Official verified donation logs.
6. `blood_requests`: Blood request registry with urgency tiers (`normal`, `urgent`, `emergency`).
7. `request_donors`: Matched donors for a given blood request categorized by distance priority tier (`within_5km`, `5_to_20km`, `20_to_50km`).
8. `donor_responses`: Donor response workflow (`interested`, `contact_me`, `cannot_donate`).
9. `contact_requests`: 2-way consent handshake for private phone number sharing.
10. `reviews`: Post-donation ratings and feedback (1–5 stars) restricted to verified interactions.
11. `notifications`: In-app and push notification feed.
12. `device_tokens`: Multi-device FCM registration tokens.
13. `organizations`: Blood banks, hospitals, and partner clubs.
14. `campaigns`: Voluntary blood drive campaigns with registration records.
15. `achievements` & `donor_achievements`: Gamified verified donation milestone awards.
16. `reports`: Abuse and fraudulent request reporting.
17. `audit_logs`: Immutable security action audit logs.
18. `app_settings`: Configurable branding, themes, and national emergency contacts.

---

## 3. Database Triggers & Automations

### Automated Donation Verification Trigger

When an authorized verifier executes `verify_donation(donation_id)`:
1. `donations.verification_status` is marked `verified`.
2. Official verified count is recalculated from scratch: `count(*) from donations where verification_status = 'verified'`.
3. Donor's status transitions to `temporarily_unavailable` with a 90-day rest period scheduled in `availability_review_due_at`.
4. Donor's badge is updated (`verified_donor`, `star_donor`, `blood_champion`, `legend`).
5. Achievements (`FIRST_DONATION`, `REGULAR_DONOR`, `LIFE_CHAMPION`, etc.) are checked and unlocked idempotently.
6. In-app and push notifications are dispatched to the donor.
