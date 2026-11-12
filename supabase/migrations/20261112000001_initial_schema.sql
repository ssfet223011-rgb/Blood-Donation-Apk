-- ====================================================================
-- BloodBond Bangladesh — National Blood Donation Mobile Platform
-- Migration 01: Initial Core Schema & PostGIS Extension
-- ====================================================================

-- 1. Enable PostGIS Extension
create extension if not exists postgis;
create extension if not exists "uuid-ossp";

-- 2. Profiles (Extends Supabase auth.users)
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null,
    phone text,
    avatar_url text,
    date_of_birth date,
    gender text check (gender in ('male', 'female', 'other')),
    blood_group text check (blood_group in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    division text not null,
    district text not null,
    upazila text,
    thana text,
    local_area text,
    is_active boolean default true,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- 3. User Roles (One user can have multiple roles)
create table if not exists public.user_roles (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    role text not null check (role in (
        'public', 'registered_user', 'donor', 'blood_seeker', 
        'volunteer', 'organization', 'moderator', 'admin', 'super_admin'
    )),
    created_at timestamptz default now(),
    unique(user_id, role)
);

-- 4. Donor Profiles
create table if not exists public.donor_profiles (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade unique,
    donor_id_number text unique not null,
    blood_group text not null check (blood_group in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    is_verified boolean default false,
    verified_at timestamptz,
    verified_by uuid references public.profiles(id),
    verification_badge text default 'unverified' check (verification_badge in ('unverified', 'verified_donor', 'star_donor', 'blood_champion', 'legend')),
    availability_status text default 'available' check (availability_status in (
        'available', 'temporarily_unavailable', 'review_due', 'resting', 'busy', 'medical_hold'
    )),
    availability_review_due_at timestamptz,
    latest_verified_donation_at timestamptz,
    total_verified_donations int default 0,
    emergency_contact_name text,
    emergency_contact_phone text,
    hide_phone_number boolean default true,
    accept_emergency_calls boolean default true,
    max_travel_distance_km int default 15,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- 5. Donor Locations (PostGIS Geometry + Obfuscated Display Coordinates)
create table if not exists public.donor_locations (
    id uuid primary key default gen_random_uuid(),
    donor_id uuid not null references public.donor_profiles(id) on delete cascade unique,
    division text not null,
    district text not null,
    upazila text,
    thana text,
    local_area text,
    geom geometry(Point, 4326),
    approx_latitude double precision,
    approx_longitude double precision,
    is_gps_enabled boolean default false,
    last_location_update timestamptz default now()
);

-- 6. Blood Requests
create table if not exists public.blood_requests (
    id uuid primary key default gen_random_uuid(),
    requester_id uuid not null references public.profiles(id) on delete cascade,
    patient_name text not null,
    blood_group text not null check (blood_group in ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    units_needed int default 1,
    units_received int default 0,
    hospital_name text not null,
    division text not null,
    district text not null,
    upazila text,
    thana text,
    hospital_address text,
    geom geometry(Point, 4326),
    urgency_level text default 'normal' check (urgency_level in ('normal', 'urgent', 'emergency')),
    required_date date not null,
    required_time text,
    contact_person_name text not null,
    contact_phone text not null,
    secondary_phone text,
    medical_reason text,
    status text default 'submitted' check (status in (
        'draft', 'submitted', 'pending_verification', 'active', 
        'matching_donors', 'donor_responses', 'fulfilled', 'completed', 'cancelled'
    )),
    is_verified boolean default false,
    verified_by uuid references public.profiles(id),
    verified_at timestamptz,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- 7. Donations (Official Log)
create table if not exists public.donations (
    id uuid primary key default gen_random_uuid(),
    donor_id uuid not null references public.donor_profiles(id) on delete cascade,
    blood_request_id uuid references public.blood_requests(id) on delete set null,
    organization_id uuid,
    donation_date timestamptz not null,
    donation_type text default 'whole_blood' check (donation_type in ('whole_blood', 'platelets', 'plasma', 'red_cells')),
    units int default 1,
    hospital_name text,
    hospital_district text,
    verification_status text default 'pending' check (verification_status in ('pending', 'verified', 'rejected')),
    notes text,
    verified_by uuid references public.profiles(id),
    verified_at timestamptz,
    certificate_id text,
    created_at timestamptz default now()
);

-- 8. Request Matched Donors
create table if not exists public.request_donors (
    id uuid primary key default gen_random_uuid(),
    blood_request_id uuid not null references public.blood_requests(id) on delete cascade,
    donor_id uuid not null references public.donor_profiles(id) on delete cascade,
    match_priority text check (match_priority in ('within_5km', '5_to_20km', '20_to_50km', 'area_match')),
    distance_km double precision,
    notified_at timestamptz,
    created_at timestamptz default now(),
    unique(blood_request_id, donor_id)
);

-- 9. Donor Responses
create table if not exists public.donor_responses (
    id uuid primary key default gen_random_uuid(),
    blood_request_id uuid not null references public.blood_requests(id) on delete cascade,
    donor_id uuid not null references public.donor_profiles(id) on delete cascade,
    response text not null check (response in ('interested', 'contact_me', 'cannot_donate')),
    notes text,
    responded_at timestamptz default now(),
    unique(blood_request_id, donor_id)
);

-- 10. Contact Requests (Consent-Based Contact Sharing)
create table if not exists public.contact_requests (
    id uuid primary key default gen_random_uuid(),
    requester_id uuid not null references public.profiles(id) on delete cascade,
    donor_id uuid not null references public.donor_profiles(id) on delete cascade,
    blood_request_id uuid references public.blood_requests(id) on delete set null,
    status text default 'pending' check (status in ('pending', 'approved', 'declined', 'expired', 'revoked')),
    request_reason text,
    expires_at timestamptz not null default (now() + interval '24 hours'),
    approved_at timestamptz,
    declined_at timestamptz,
    created_at timestamptz default now()
);

-- 11. Reviews (Verified interactions only)
create table if not exists public.reviews (
    id uuid primary key default gen_random_uuid(),
    reviewer_id uuid not null references public.profiles(id) on delete cascade,
    donor_id uuid not null references public.donor_profiles(id) on delete cascade,
    blood_request_id uuid not null references public.blood_requests(id) on delete cascade,
    rating int not null check (rating >= 1 and rating <= 5),
    review_text text,
    moderation_status text default 'approved' check (moderation_status in ('pending', 'approved', 'rejected', 'hidden')),
    moderated_by uuid references public.profiles(id),
    created_at timestamptz default now(),
    unique(reviewer_id, donor_id, blood_request_id)
);

-- 12. Notifications
create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    category text not null check (category in (
        'EMERGENCY_REQUEST', 'MATCHING_REQUEST', 'CONTACT_REQUEST', 
        'DONOR_RESPONSE', 'DONATION_VERIFIED', 'AVAILABILITY_REVIEW', 
        'REVIEW_RECEIVED', 'SYSTEM_ANNOUNCEMENT'
    )),
    title text not null,
    body text not null,
    data jsonb default '{}'::jsonb,
    is_read boolean default false,
    created_at timestamptz default now()
);

-- 13. Device Tokens (FCM Push Notifications)
create table if not exists public.device_tokens (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    token text not null unique,
    platform text default 'android' check (platform in ('android', 'ios', 'web')),
    device_name text,
    last_seen timestamptz default now(),
    created_at timestamptz default now()
);

-- 14. Organizations
create table if not exists public.organizations (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    type text default 'blood_bank' check (type in ('blood_bank', 'hospital', 'ngo', 'volunteer_club', 'red_crescent')),
    division text not null,
    district text not null,
    upazila text,
    address text,
    contact_phone text,
    email text,
    logo_url text,
    is_verified boolean default false,
    created_at timestamptz default now()
);

-- 15. Campaigns
create table if not exists public.campaigns (
    id uuid primary key default gen_random_uuid(),
    organization_id uuid references public.organizations(id) on delete cascade,
    title text not null,
    description text,
    banner_image_url text,
    division text not null,
    district text not null,
    venue text not null,
    start_date timestamptz not null,
    end_date timestamptz not null,
    target_units int default 50,
    collected_units int default 0,
    status text default 'upcoming' check (status in ('upcoming', 'active', 'completed', 'cancelled')),
    created_at timestamptz default now()
);

-- 16. Campaign Registrations
create table if not exists public.campaign_registrations (
    id uuid primary key default gen_random_uuid(),
    campaign_id uuid not null references public.campaigns(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    status text default 'registered' check (status in ('registered', 'attended', 'donated', 'cancelled')),
    registered_at timestamptz default now(),
    unique(campaign_id, user_id)
);

-- 17. Achievements Definitions
create table if not exists public.achievements (
    id text primary key,
    title text not null,
    description text not null,
    icon_name text not null,
    donations_required int not null,
    created_at timestamptz default now()
);

-- 18. Donor Achievements
create table if not exists public.donor_achievements (
    id uuid primary key default gen_random_uuid(),
    donor_id uuid not null references public.donor_profiles(id) on delete cascade,
    achievement_id text not null references public.achievements(id) on delete cascade,
    unlocked_at timestamptz default now(),
    unique(donor_id, achievement_id)
);

-- 19. Abuse & Fraud Reports
create table if not exists public.reports (
    id uuid primary key default gen_random_uuid(),
    reporter_id uuid not null references public.profiles(id) on delete cascade,
    target_type text not null check (target_type in ('user', 'donor', 'blood_request', 'review')),
    target_id uuid not null,
    reason text not null,
    details text,
    status text default 'pending' check (status in ('pending', 'investigating', 'resolved', 'dismissed')),
    reviewed_by uuid references public.profiles(id),
    created_at timestamptz default now()
);

-- 20. Audit Logs
create table if not exists public.audit_logs (
    id uuid primary key default gen_random_uuid(),
    actor_id uuid references public.profiles(id),
    action text not null,
    entity_type text not null,
    entity_id text,
    metadata jsonb default '{}'::jsonb,
    ip_address text,
    created_at timestamptz default now()
);

-- 21. Configurable App Settings
create table if not exists public.app_settings (
    key text primary key,
    value jsonb not null,
    updated_at timestamptz default now()
);

-- Indexes for performance
create index if not exists idx_profiles_phone on public.profiles(phone);
create index if not exists idx_profiles_district on public.profiles(district);
create index if not exists idx_donor_profiles_blood_group on public.donor_profiles(blood_group);
create index if not exists idx_donor_profiles_availability on public.donor_profiles(availability_status);
create index if not exists idx_donor_locations_geom on public.donor_locations using gist(geom);
create index if not exists idx_blood_requests_geom on public.blood_requests using gist(geom);
create index if not exists idx_blood_requests_status on public.blood_requests(status);
create index if not exists idx_blood_requests_urgency on public.blood_requests(urgency_level);
create index if not exists idx_donations_donor on public.donations(donor_id);
create index if not exists idx_contact_requests_donor on public.contact_requests(donor_id);
create index if not exists idx_notifications_user on public.notifications(user_id, is_read);
