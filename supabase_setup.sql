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
-- ====================================================================
-- BloodBond Bangladesh — National Blood Donation Mobile Platform
-- Migration 02: PostGIS Functions & Secure RPCs
-- ====================================================================

-- Function: Blood Group Compatibility Check
create or replace function public.is_blood_compatible(donor_group text, recipient_group text)
returns boolean language plpgsql immutable as $$
begin
    -- Exact match is always compatible
    if donor_group = recipient_group then
        return true;
    end if;

    -- O- is universal red blood cell donor
    if donor_group = 'O-' then
        return true;
    end if;

    -- O+ can donate to O+, A+, B+, AB+
    if donor_group = 'O+' and recipient_group in ('O+', 'A+', 'B+', 'AB+') then
        return true;
    end if;

    -- A- can donate to A-, A+, AB-, AB+
    if donor_group = 'A-' and recipient_group in ('A-', 'A+', 'AB-', 'AB+') then
        return true;
    end if;

    -- A+ can donate to A+, AB+
    if donor_group = 'A+' and recipient_group in ('A+', 'AB+') then
        return true;
    end if;

    -- B- can donate to B-, B+, AB-, AB+
    if donor_group = 'B-' and recipient_group in ('B-', 'B+', 'AB-', 'AB+') then
        return true;
    end if;

    -- B+ can donate to B+, AB+
    if donor_group = 'B+' and recipient_group in ('B+', 'AB+') then
        return true;
    end if;

    -- AB- can donate to AB-, AB+
    if donor_group = 'AB-' and recipient_group in ('AB-', 'AB+') then
        return true;
    end if;

    return false;
end;
$$;

-- Secure PostGIS RPC: Nearby Donor Search with Privacy Obfuscation
-- CRITICAL: Phone numbers and exact coordinates are strictly excluded from output!
create or replace function public.search_nearby_donors(
    p_blood_group text default null,
    p_latitude double precision default null,
    p_longitude double precision default null,
    p_max_radius_km double precision default 50.0,
    p_division text default null,
    p_district text default null,
    p_upazila text default null,
    p_availability_only boolean default true,
    p_limit int default 50,
    p_offset int default 0
)
returns table (
    donor_id uuid,
    donor_id_number text,
    full_name text,
    avatar_url text,
    blood_group text,
    is_verified boolean,
    verification_badge text,
    availability_status text,
    total_verified_donations int,
    division text,
    district text,
    upazila text,
    thana text,
    local_area text,
    approx_latitude double precision,
    approx_longitude double precision,
    distance_km double precision,
    distance_tier text,
    avg_rating double precision,
    total_reviews bigint
)
language plpgsql
security definer
as $$
declare
    v_search_geom geometry;
begin
    if p_latitude is not null and p_longitude is not null then
        v_search_geom := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326);
    end if;

    return query
    with donor_ratings as (
        select 
            r.donor_id as d_id,
            coalesce(avg(r.rating)::numeric(3, 2), 5.0)::double precision as rating_avg,
            count(r.id) as review_cnt
        from public.reviews r
        where r.moderation_status = 'approved'
        group by r.donor_id
    ),
    filtered_donors as (
        select 
            dp.id as f_donor_id,
            dp.donor_id_number as f_donor_id_number,
            p.full_name as f_full_name,
            p.avatar_url as f_avatar_url,
            dp.blood_group as f_blood_group,
            dp.is_verified as f_is_verified,
            dp.verification_badge as f_verification_badge,
            dp.availability_status as f_availability_status,
            dp.total_verified_donations as f_total_verified_donations,
            dl.division as f_division,
            dl.district as f_district,
            dl.upazila as f_upazila,
            dl.thana as f_thana,
            dl.local_area as f_local_area,
            -- Obfuscated coordinates for privacy (rounded to ~1km or approx coordinates)
            coalesce(dl.approx_latitude, round(ST_Y(dl.geom)::numeric, 2)::double precision) as f_approx_lat,
            coalesce(dl.approx_longitude, round(ST_X(dl.geom)::numeric, 2)::double precision) as f_approx_lon,
            case 
                when v_search_geom is not null and dl.geom is not null then
                    round((ST_DistanceSphere(dl.geom, v_search_geom) / 1000.0)::numeric, 2)::double precision
                else null
            end as f_distance_km
        from public.donor_profiles dp
        join public.profiles p on p.id = dp.user_id
        left join public.donor_locations dl on dl.donor_id = dp.id
        where p.is_active = true
          and (p_blood_group is null or dp.blood_group = p_blood_group)
          and (not p_availability_only or dp.availability_status = 'available')
          and (p_division is null or dl.division = p_division or p.division = p_division)
          and (p_district is null or dl.district = p_district or p.district = p_district)
          and (p_upazila is null or dl.upazila = p_upazila or p.upazila = p_upazila)
          and (
              v_search_geom is null 
              or dl.geom is null 
              or ST_DistanceSphere(dl.geom, v_search_geom) <= (p_max_radius_km * 1000.0)
          )
    )
    select 
        fd.f_donor_id,
        fd.f_donor_id_number,
        fd.f_full_name,
        fd.f_avatar_url,
        fd.f_blood_group,
        fd.f_is_verified,
        fd.f_verification_badge,
        fd.f_availability_status,
        fd.f_total_verified_donations,
        fd.f_division,
        fd.f_district,
        fd.f_upazila,
        fd.f_thana,
        fd.f_local_area,
        fd.f_approx_lat,
        fd.f_approx_lon,
        fd.f_distance_km,
        case 
            when fd.f_distance_km is null then 'area_match'
            when fd.f_distance_km <= 5.0 then 'within_5km'
            when fd.f_distance_km <= 20.0 then '5_to_20km'
            else '20_to_50km'
        end as distance_tier,
        coalesce(dr.rating_avg, 5.0),
        coalesce(dr.review_cnt, 0)
    from filtered_donors fd
    left join donor_ratings dr on dr.d_id = fd.f_donor_id
    order by 
        -- Priority 1: Distance priority tiers (5km first, then 5-20km, then 20-50km)
        case 
            when fd.f_distance_km is not null and fd.f_distance_km <= 5.0 then 1
            when fd.f_distance_km is not null and fd.f_distance_km <= 20.0 then 2
            when fd.f_distance_km is not null and fd.f_distance_km <= 50.0 then 3
            else 4
        end asc,
        -- Priority 2: Distance itself
        fd.f_distance_km asc nulls last,
        -- Priority 3: Verification status
        fd.f_is_verified desc,
        -- Priority 4: Verified donation count
        fd.f_total_verified_donations desc
    limit p_limit
    offset p_offset;
end;
$$;

-- Secure PostGIS RPC: Emergency Donor Matching
create or replace function public.match_emergency_donors(
    p_blood_request_id uuid,
    p_max_donors int default 20
)
returns int
language plpgsql
security definer
as $$
declare
    v_request record;
    v_matched_count int := 0;
    v_donor record;
    v_distance_km double precision;
    v_priority text;
begin
    -- 1. Fetch request details
    select * into v_request from public.blood_requests where id = p_blood_request_id;
    if not found then
        raise exception 'Blood request not found';
    end if;

    -- 2. Find eligible donors who are available and blood-compatible
    for v_donor in
        select 
            dp.id as donor_id,
            dp.user_id,
            dl.geom,
            case 
                when v_request.geom is not null and dl.geom is not null then
                    (ST_DistanceSphere(dl.geom, v_request.geom) / 1000.0)
                else null
            end as calc_distance
        from public.donor_profiles dp
        join public.donor_locations dl on dl.donor_id = dp.id
        where dp.availability_status = 'available'
          and public.is_blood_compatible(dp.blood_group, v_request.blood_group)
          and (
              v_request.geom is null 
              or dl.geom is null 
              or ST_DistanceSphere(dl.geom, v_request.geom) <= 50000.0 -- 50km
              or dl.district = v_request.district
          )
        order by 
            case 
                when v_request.geom is not null and dl.geom is not null and ST_DistanceSphere(dl.geom, v_request.geom) <= 5000.0 then 1
                when v_request.geom is not null and dl.geom is not null and ST_DistanceSphere(dl.geom, v_request.geom) <= 20000.0 then 2
                else 3
            end asc,
            dp.total_verified_donations desc
        limit p_max_donors
    loop
        v_distance_km := v_donor.calc_distance;
        if v_distance_km is not null and v_distance_km <= 5.0 then
            v_priority := 'within_5km';
        elsif v_distance_km is not null and v_distance_km <= 20.0 then
            v_priority := '5_to_20km';
        elsif v_distance_km is not null and v_distance_km <= 50.0 then
            v_priority := '20_to_50km';
        else
            v_priority := 'area_match';
        end if;

        -- Insert into request_donors if not already matched
        insert into public.request_donors (
            blood_request_id,
            donor_id,
            match_priority,
            distance_km,
            notified_at
        ) values (
            p_blood_request_id,
            v_donor.donor_id,
            v_priority,
            v_distance_km,
            now()
        ) on conflict (blood_request_id, donor_id) do nothing;

        -- Create emergency in-app notification (Privacy safe text without patient PII on notification)
        insert into public.notifications (
            user_id,
            category,
            title,
            body,
            data
        ) values (
            v_donor.user_id,
            'EMERGENCY_REQUEST',
            '🚨 Emergency Blood Request',
            'Matching ' || v_request.blood_group || ' blood is urgently needed near your area. Open BloodBond to review details.',
            jsonb_build_object(
                'blood_request_id', p_blood_request_id,
                'blood_group', v_request.blood_group,
                'district', v_request.district,
                'urgency', v_request.urgency_level
            )
        );

        v_matched_count := v_matched_count + 1;
    end loop;

    -- Update request status
    update public.blood_requests 
    set status = 'matching_donors', updated_at = now()
    where id = p_blood_request_id;

    return v_matched_count;
end;
$$;

-- Secure RPC: Digital ID Verification (QR code verification target)
-- Safe for public/seeker access without leaking sensitive PII
create or replace function public.verify_donor_id(
    p_donor_id_number text
)
returns table (
    donor_id_number text,
    full_name text,
    avatar_url text,
    blood_group text,
    district text,
    verification_badge text,
    is_verified boolean,
    verified_at timestamptz,
    total_verified_donations int,
    member_since timestamptz
)
language plpgsql
security definer
as $$
begin
    return query
    select 
        dp.donor_id_number,
        p.full_name,
        p.avatar_url,
        dp.blood_group,
        p.district,
        dp.verification_badge,
        dp.is_verified,
        dp.verified_at,
        dp.total_verified_donations,
        dp.created_at as member_since
    from public.donor_profiles dp
    join public.profiles p on p.id = dp.user_id
    where dp.donor_id_number = p_donor_id_number;
end;
$$;

-- Secure RPC: Consent Approval for Contact Sharing
create or replace function public.approve_contact_request(
    p_contact_request_id uuid
)
returns jsonb
language plpgsql
security definer
as $$
declare
    v_req record;
    v_donor record;
    v_requester record;
    v_donor_phone text;
begin
    -- 1. Fetch contact request
    select * into v_req from public.contact_requests where id = p_contact_request_id;
    if not found then
        return jsonb_build_object('success', false, 'message', 'Contact request not found');
    end if;

    -- 2. Verify caller is the actual donor
    select dp.*, p.phone into v_donor 
    from public.donor_profiles dp
    join public.profiles p on p.id = dp.user_id
    where dp.id = v_req.donor_id and dp.user_id = auth.uid();

    if not found then
        return jsonb_build_object('success', false, 'message', 'Unauthorized: Only the requested donor can approve contact');
    end if;

    -- 3. Update contact request status
    update public.contact_requests 
    set 
        status = 'approved',
        approved_at = now(),
        expires_at = now() + interval '48 hours'
    where id = p_contact_request_id;

    -- 4. Notify requester
    insert into public.notifications (
        user_id,
        category,
        title,
        body,
        data
    ) values (
        v_req.requester_id,
        'CONTACT_REQUEST',
        '✅ Contact Request Approved',
        'The donor has approved your contact request. You may now contact them via the app.',
        jsonb_build_object(
            'contact_request_id', p_contact_request_id,
            'donor_id', v_req.donor_id,
            'status', 'approved'
        )
    );

    -- 5. Audit Log
    insert into public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
    values (auth.uid(), 'APPROVE_CONTACT', 'contact_requests', p_contact_request_id::text, jsonb_build_object('requester_id', v_req.requester_id));

    return jsonb_build_object('success', true, 'status', 'approved', 'expires_at', now() + interval '48 hours');
end;
$$;
-- ====================================================================
-- BloodBond Bangladesh — National Blood Donation Mobile Platform
-- Migration 03: Triggers, Automations & Verification Workflows
-- ====================================================================

-- 1. Helper Function: Generate Formatted Donor ID Number (e.g., BB-DHA-000001)
create or replace function public.generate_donor_id_number(p_district text)
returns text language plpgsql as $$
declare
    v_prefix text;
    v_seq_num int;
    v_new_id text;
begin
    -- Determine 3-letter district prefix
    case upper(coalesce(p_district, 'GEN'))
        when 'DHAKA' then v_prefix := 'DHA';
        when 'CHATTOGRAM' then v_prefix := 'CTG';
        when 'CHITTAGONG' then v_prefix := 'CTG';
        when 'RAJSHAHI' then v_prefix := 'RAJ';
        when 'KHULNA' then v_prefix := 'KHU';
        when 'BARISHAL' then v_prefix := 'BAR';
        when 'SYLHET' then v_prefix := 'SYL';
        when 'RANGPUR' then v_prefix := 'RAN';
        when 'MYMENSINGH' then v_prefix := 'MYM';
        when 'COMILLA' then v_prefix := 'COM';
        when 'CUMILLA' then v_prefix := 'CUM';
        when 'GAZIPUR' then v_prefix := 'GAZ';
        when 'BOGURA' then v_prefix := 'BOG';
        else v_prefix := upper(substring(coalesce(p_district, 'BBD') from 1 for 3));
    end case;

    -- Count existing donors with this prefix to get next sequence number
    select count(*) + 1 into v_seq_num 
    from public.donor_profiles 
    where donor_id_number like 'BB-' || v_prefix || '-%';

    v_new_id := 'BB-' || v_prefix || '-' || lpad(v_seq_num::text, 6, '0');
    return v_new_id;
end;
$$;

-- 2. Trigger Function: Auto-populate Donor ID and initial role on new donor registration
create or replace function public.handle_new_donor_registration()
returns trigger language plpgsql as $$
declare
    v_district text;
begin
    if NEW.donor_id_number is null or NEW.donor_id_number = '' then
        select district into v_district from public.profiles where id = NEW.user_id;
        NEW.donor_id_number := public.generate_donor_id_number(v_district);
    end if;

    -- Add 'donor' role to user_roles
    insert into public.user_roles (user_id, role)
    values (NEW.user_id, 'donor')
    on conflict (user_id, role) do nothing;

    return NEW;
end;
$$;

create or replace trigger trg_before_insert_donor_profile
before insert on public.donor_profiles
for each row execute function public.handle_new_donor_registration();

-- 3. Procedure / RPC: Verify a Donation Record
create or replace function public.verify_donation(
    p_donation_id uuid,
    p_notes text default null
)
returns jsonb
language plpgsql
security definer
as $$
declare
    v_donation record;
    v_donor record;
    v_caller_role record;
    v_total_verified int;
    v_badge text;
begin
    -- 1. Check if caller has verification privileges (admin, moderator, volunteer, organization)
    select role into v_caller_role 
    from public.user_roles 
    where user_id = auth.uid() 
      and role in ('admin', 'super_admin', 'moderator', 'volunteer', 'organization')
    limit 1;

    if not found and auth.role() <> 'service_role' then
        return jsonb_build_object('success', false, 'message', 'Unauthorized: Requires verification role');
    end if;

    -- 2. Get donation record
    select * into v_donation from public.donations where id = p_donation_id;
    if not found then
        return jsonb_build_object('success', false, 'message', 'Donation record not found');
    end if;

    if v_donation.verification_status = 'verified' then
        return jsonb_build_object('success', true, 'message', 'Donation is already verified');
    end if;

    -- 3. Update donation status
    update public.donations
    set 
        verification_status = 'verified',
        verified_by = auth.uid(),
        verified_at = now(),
        notes = coalesce(p_notes, notes)
    where id = p_donation_id;

    -- 4. Calculate total verified donations for this donor (server-side official calculation)
    select count(*) into v_total_verified
    from public.donations
    where donor_id = v_donation.donor_id and verification_status = 'verified';

    -- Determine badge
    if v_total_verified >= 25 then
        v_badge := 'legend';
    elsif v_total_verified >= 10 then
        v_badge := 'blood_champion';
    elsif v_total_verified >= 5 then
        v_badge := 'star_donor';
    elsif v_total_verified >= 1 then
        v_badge := 'verified_donor';
    else
        v_badge := 'unverified';
    end if;

    -- 5. Update Donor Profile:
    -- - Update verified count
    -- - Update latest verified donation timestamp
    -- - Put on 90-day rest period: temporarily_unavailable
    -- - Set review due date to 90 days from donation date
    update public.donor_profiles
    set 
        total_verified_donations = v_total_verified,
        latest_verified_donation_at = v_donation.donation_date,
        availability_status = 'temporarily_unavailable',
        availability_review_due_at = v_donation.donation_date + interval '90 days',
        is_verified = true,
        verified_at = coalesce(verified_at, now()),
        verification_badge = v_badge,
        updated_at = now()
    where id = v_donation.donor_id
    returning * into v_donor;

    -- 6. Trigger achievements evaluation
    perform public.evaluate_donor_achievements(v_donation.donor_id, v_total_verified);

    -- 7. Notify donor
    insert into public.notifications (
        user_id,
        category,
        title,
        body,
        data
    ) values (
        v_donor.user_id,
        'DONATION_VERIFIED',
        '🎉 Donation Verified!',
        'Your blood donation on ' || to_char(v_donation.donation_date, 'DD Mon YYYY') || ' has been officially verified. Total verified donations: ' || v_total_verified || '.',
        jsonb_build_object(
            'donation_id', p_donation_id,
            'total_verified', v_total_verified,
            'badge', v_badge,
            'next_review', (v_donation.donation_date + interval '90 days')
        )
    );

    -- 8. Audit log
    insert into public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
    values (
        auth.uid(),
        'VERIFY_DONATION',
        'donations',
        p_donation_id::text,
        jsonb_build_object('donor_id', v_donation.donor_id, 'total_verified', v_total_verified)
    );

    return jsonb_build_object(
        'success', true, 
        'total_verified_donations', v_total_verified,
        'verification_badge', v_badge,
        'availability_status', 'temporarily_unavailable'
    );
end;
$$;

-- 4. Achievement Evaluator
create or replace function public.evaluate_donor_achievements(
    p_donor_id uuid,
    p_total_verified int
)
returns void language plpgsql as $$
declare
    v_donor record;
    v_ach record;
begin
    select * into v_donor from public.donor_profiles where id = p_donor_id;
    if not found then return; end if;

    for v_ach in select * from public.achievements where donations_required <= p_total_verified loop
        -- Insert into donor_achievements if not already unlocked
        insert into public.donor_achievements (donor_id, achievement_id, unlocked_at)
        values (p_donor_id, v_ach.id, now())
        on conflict (donor_id, achievement_id) do nothing;
    end loop;
end;
$$;

-- 5. Automated Availability Review Job
-- Scans for donors whose 90-day rest period has passed and transitions them to 'review_due'
create or replace function public.check_availability_reviews()
returns int language plpgsql security definer as $$
declare
    v_updated_count int := 0;
    v_record record;
begin
    for v_record in 
        select dp.id, dp.user_id, dp.availability_review_due_at
        from public.donor_profiles dp
        where dp.availability_status = 'temporarily_unavailable'
          and dp.availability_review_due_at is not null
          and dp.availability_review_due_at <= now()
    loop
        update public.donor_profiles
        set availability_status = 'review_due', updated_at = now()
        where id = v_record.id;

        -- Send notification to donor
        insert into public.notifications (
            user_id,
            category,
            title,
            body,
            data
        ) values (
            v_record.user_id,
            'AVAILABILITY_REVIEW',
            '🩸 Availability Review Due',
            'Your 90-day rest period is complete. Please review your availability status in BloodBond before accepting new donation requests.',
            jsonb_build_object('donor_id', v_record.id, 'action', 'review_availability')
        );

        v_updated_count := v_updated_count + 1;
    end loop;

    return v_updated_count;
end;
$$;

-- 6. Trigger: Update Blood Request Status on Donor Responses
create or replace function public.handle_donor_response()
returns trigger language plpgsql as $$
declare
    v_req record;
begin
    select * into v_req from public.blood_requests where id = NEW.blood_request_id;
    if found then
        -- Notify the blood requester
        insert into public.notifications (
            user_id,
            category,
            title,
            body,
            data
        ) values (
            v_req.requester_id,
            'DONOR_RESPONSE',
            '🩸 Donor Response Received',
            'A donor has responded (' || NEW.response || ') to your blood request for ' || v_req.patient_name || '.',
            jsonb_build_object('blood_request_id', NEW.blood_request_id, 'donor_id', NEW.donor_id, 'response', NEW.response)
        );

        if v_req.status = 'matching_donors' then
            update public.blood_requests 
            set status = 'donor_responses', updated_at = now()
            where id = NEW.blood_request_id;
        end if;
    end if;

    return NEW;
end;
$$;

create or replace trigger trg_donor_response
after insert or update on public.donor_responses
for each row execute function public.handle_donor_response();
-- ====================================================================
-- BloodBond Bangladesh — National Blood Donation Mobile Platform
-- Migration 04: Row Level Security (RLS) & Access Control
-- ====================================================================

-- 1. Helper function to check admin / moderator status
create or replace function public.is_admin_or_moderator(user_uuid uuid)
returns boolean language sql security definer as $$
    select exists (
        select 1 from public.user_roles 
        where user_id = user_uuid and role in ('admin', 'super_admin', 'moderator')
    );
$$;

create or replace function public.is_staff_or_admin(user_uuid uuid)
returns boolean language sql security definer as $$
    select exists (
        select 1 from public.user_roles 
        where user_id = user_uuid and role in ('admin', 'super_admin', 'moderator', 'volunteer', 'organization')
    );
$$;

-- 2. Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.donor_profiles enable row level security;
alter table public.donor_locations enable row level security;
alter table public.donations enable row level security;
alter table public.blood_requests enable row level security;
alter table public.request_donors enable row level security;
alter table public.donor_responses enable row level security;
alter table public.contact_requests enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;
alter table public.organizations enable row level security;
alter table public.campaigns enable row level security;
alter table public.campaign_registrations enable row level security;
alter table public.achievements enable row level security;
alter table public.donor_achievements enable row level security;
alter table public.reports enable row level security;
alter table public.audit_logs enable row level security;
alter table public.app_settings enable row level security;

-- ====================================================================
-- POLICIES: profiles
-- ====================================================================
create policy "Profiles: authenticated users can view basic active profiles"
    on public.profiles for select
    to authenticated
    using (is_active = true or auth.uid() = id or public.is_admin_or_moderator(auth.uid()));

create policy "Profiles: users can update own profile"
    on public.profiles for update
    to authenticated
    using (auth.uid() = id);

create policy "Profiles: users can insert their own profile"
    on public.profiles for insert
    to authenticated
    with check (auth.uid() = id);

-- ====================================================================
-- POLICIES: user_roles
-- ====================================================================
create policy "UserRoles: users can view their own roles"
    on public.user_roles for select
    to authenticated
    using (auth.uid() = user_id or public.is_admin_or_moderator(auth.uid()));

create policy "UserRoles: only admins can manage roles"
    on public.user_roles for all
    to authenticated
    using (public.is_admin_or_moderator(auth.uid()));

-- ====================================================================
-- POLICIES: donor_profiles
-- ====================================================================
create policy "DonorProfiles: viewable by authenticated users"
    on public.donor_profiles for select
    to authenticated
    using (true);

create policy "DonorProfiles: donors can update their own profile"
    on public.donor_profiles for update
    to authenticated
    using (auth.uid() = user_id);

create policy "DonorProfiles: donors can insert their own profile"
    on public.donor_profiles for insert
    to authenticated
    with check (auth.uid() = user_id);

-- ====================================================================
-- POLICIES: donor_locations
-- ====================================================================
-- Exact coordinates are strictly isolated. Users can only select their own exact coordinates.
-- General proximity search is done via PostGIS RPC search_nearby_donors.
create policy "DonorLocations: donors view their own exact location"
    on public.donor_locations for select
    to authenticated
    using (donor_id in (select id from public.donor_profiles where user_id = auth.uid()) or public.is_admin_or_moderator(auth.uid()));

create policy "DonorLocations: donors manage their own location"
    on public.donor_locations for all
    to authenticated
    using (donor_id in (select id from public.donor_profiles where user_id = auth.uid()));

-- ====================================================================
-- POLICIES: blood_requests
-- ====================================================================
create policy "BloodRequests: viewable by authenticated users"
    on public.blood_requests for select
    to authenticated
    using (status in ('active', 'matching_donors', 'donor_responses', 'fulfilled', 'completed') or requester_id = auth.uid() or public.is_admin_or_moderator(auth.uid()));

create policy "BloodRequests: requesters can insert requests"
    on public.blood_requests for insert
    to authenticated
    with check (requester_id = auth.uid());

create policy "BloodRequests: requesters can update own requests"
    on public.blood_requests for update
    to authenticated
    using (requester_id = auth.uid() or public.is_admin_or_moderator(auth.uid()));

-- ====================================================================
-- POLICIES: donations
-- ====================================================================
create policy "Donations: donors can view own donations"
    on public.donations for select
    to authenticated
    using (donor_id in (select id from public.donor_profiles where user_id = auth.uid()) or public.is_staff_or_admin(auth.uid()));

create policy "Donations: staff/admins can insert and manage donations"
    on public.donations for all
    to authenticated
    using (public.is_staff_or_admin(auth.uid()));

-- ====================================================================
-- POLICIES: contact_requests (Consent-Based Sharing)
-- ====================================================================
create policy "ContactRequests: requesters and donors can view their requests"
    on public.contact_requests for select
    to authenticated
    using (
        requester_id = auth.uid() 
        or donor_id in (select id from public.donor_profiles where user_id = auth.uid())
        or public.is_admin_or_moderator(auth.uid())
    );

create policy "ContactRequests: requesters can create requests"
    on public.contact_requests for insert
    to authenticated
    with check (requester_id = auth.uid());

create policy "ContactRequests: donors can respond to requests"
    on public.contact_requests for update
    to authenticated
    using (donor_id in (select id from public.donor_profiles where user_id = auth.uid()) or public.is_admin_or_moderator(auth.uid()));

-- ====================================================================
-- POLICIES: donor_responses
-- ====================================================================
create policy "DonorResponses: donors and requesters can view"
    on public.donor_responses for select
    to authenticated
    using (
        donor_id in (select id from public.donor_profiles where user_id = auth.uid())
        or blood_request_id in (select id from public.blood_requests where requester_id = auth.uid())
        or public.is_admin_or_moderator(auth.uid())
    );

create policy "DonorResponses: donors can insert and update their responses"
    on public.donor_responses for all
    to authenticated
    using (donor_id in (select id from public.donor_profiles where user_id = auth.uid()));

-- ====================================================================
-- POLICIES: reviews
-- ====================================================================
create policy "Reviews: view approved reviews"
    on public.reviews for select
    to authenticated
    using (moderation_status = 'approved' or reviewer_id = auth.uid() or public.is_admin_or_moderator(auth.uid()));

create policy "Reviews: reviewers can create verified reviews"
    on public.reviews for insert
    to authenticated
    with check (reviewer_id = auth.uid());

create policy "Reviews: moderators can manage reviews"
    on public.reviews for update
    to authenticated
    using (public.is_admin_or_moderator(auth.uid()));

-- ====================================================================
-- POLICIES: notifications
-- ====================================================================
create policy "Notifications: users manage their own notifications"
    on public.notifications for all
    to authenticated
    using (user_id = auth.uid());

-- ====================================================================
-- POLICIES: device_tokens
-- ====================================================================
create policy "DeviceTokens: users manage their own tokens"
    on public.device_tokens for all
    to authenticated
    using (user_id = auth.uid());

-- ====================================================================
-- POLICIES: organizations & campaigns
-- ====================================================================
create policy "Organizations: public read"
    on public.organizations for select
    to authenticated
    using (true);

create policy "Campaigns: public read"
    on public.campaigns for select
    to authenticated
    using (true);

create policy "CampaignRegistrations: users manage own registration"
    on public.campaign_registrations for all
    to authenticated
    using (user_id = auth.uid());

-- ====================================================================
-- POLICIES: achievements
-- ====================================================================
create policy "Achievements: public read"
    on public.achievements for select
    to authenticated
    using (true);

create policy "DonorAchievements: viewable by authenticated users"
    on public.donor_achievements for select
    to authenticated
    using (true);

-- ====================================================================
-- POLICIES: reports & audit_logs
-- ====================================================================
create policy "Reports: authenticated can insert reports"
    on public.reports for insert
    to authenticated
    with check (reporter_id = auth.uid());

create policy "Reports: admins manage reports"
    on public.reports for all
    to authenticated
    using (public.is_admin_or_moderator(auth.uid()));

create policy "AuditLogs: admins view logs"
    on public.audit_logs for select
    to authenticated
    using (public.is_admin_or_moderator(auth.uid()));

-- ====================================================================
-- POLICIES: app_settings
-- ====================================================================
create policy "AppSettings: public read"
    on public.app_settings for select
    to authenticated
    using (true);

create policy "AppSettings: admins manage settings"
    on public.app_settings for all
    to authenticated
    using (public.is_admin_or_moderator(auth.uid()));
-- ====================================================================
-- BloodBond Bangladesh — National Blood Donation Mobile Platform
-- Migration 05: Storage Buckets & Access Policies
-- ====================================================================

-- 1. Create Storage Buckets
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values 
    ('profile-photos', 'profile-photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
    ('organization-logos', 'organization-logos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']),
    ('campaign-images', 'campaign-images', true, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
    ('verification-documents', 'verification-documents', false, 15728640, array['image/jpeg', 'image/png', 'application/pdf'])
on conflict (id) do nothing;

-- 2. Storage Policies for Profile Photos
create policy "Profile Photos: Anyone can view"
    on storage.objects for select
    using (bucket_id = 'profile-photos');

create policy "Profile Photos: Authenticated users upload to own folder"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Profile Photos: Authenticated users update own photos"
    on storage.objects for update
    to authenticated
    using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Profile Photos: Authenticated users delete own photos"
    on storage.objects for delete
    to authenticated
    using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- 3. Storage Policies for Verification Documents (Private, signed URLs)
create policy "Verification Docs: Users view own documents"
    on storage.objects for select
    to authenticated
    using (
        bucket_id = 'verification-documents' and (
            (storage.foldername(name))[1] = auth.uid()::text 
            or public.is_admin_or_moderator(auth.uid())
        )
    );

create policy "Verification Docs: Users upload own documents"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'verification-documents' and (storage.foldername(name))[1] = auth.uid()::text);

-- 4. Storage Policies for Campaigns and Organizations
create policy "Campaign Images: Public view"
    on storage.objects for select
    using (bucket_id = 'campaign-images');

create policy "Organization Logos: Public view"
    on storage.objects for select
    using (bucket_id = 'organization-logos');

create policy "Campaign Images: Staff upload"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'campaign-images' and public.is_staff_or_admin(auth.uid()));

create policy "Organization Logos: Staff upload"
    on storage.objects for insert
    to authenticated
    with check (bucket_id = 'organization-logos' and public.is_staff_or_admin(auth.uid()));
-- ====================================================================
-- BloodBond Bangladesh — National Blood Donation Mobile Platform
-- Migration 06: Seed Data (Achievements, App Settings, Organizations)
-- ====================================================================

-- 1. Seed Achievements
insert into public.achievements (id, title, description, icon_name, donations_required)
values 
    ('FIRST_DONATION', 'First Drop of Hope', 'Completed your very first voluntary blood donation.', 'water_drop', 1),
    ('REGULAR_DONOR', 'Consistent Lifesaver', 'Completed 5 verified blood donations.', 'favorite', 5),
    ('LIFE_CHAMPION', 'Life Champion', 'Completed 10 verified blood donations.', 'military_tech', 10),
    ('BLOOD_HERO', 'National Blood Hero', 'Completed 25 verified blood donations.', 'workspace_premium', 25),
    ('CENTURION', 'Living Legend', 'Completed 50+ verified blood donations.', 'diamond', 50)
on conflict (id) do update set 
    title = excluded.title, 
    description = excluded.description, 
    donations_required = excluded.donations_required;

-- 2. Seed Default App Settings (Configurable Branding System)
insert into public.app_settings (key, value)
values 
    ('branding', '{
        "app_name": "BloodBond Bangladesh",
        "tagline": "Every Drop Connects a Life.",
        "primary_color": "#C62828",
        "secondary_color": "#0D1B2A",
        "accent_color": "#E53935",
        "background_color": "#FFFFFF",
        "emergency_color": "#D32F2F",
        "success_color": "#2E7D32",
        "logo_url": "https://bloodbond.bd/assets/logo.png",
        "contact_email": "support@bloodbond.bd",
        "contact_phone": "+8809612000000",
        "emergency_hotline": "999",
        "website_url": "https://bloodbond.bd"
    }'::jsonb),
    ('eligibility_rules', '{
        "min_age": 18,
        "max_age": 60,
        "min_weight_male_kg": 50,
        "min_weight_female_kg": 45,
        "donation_cooldown_days": 90,
        "review_due_notice_days": 90
    }'::jsonb),
    ('geo_search_tiers', '{
        "tier_1_max_km": 5,
        "tier_2_max_km": 20,
        "tier_3_max_km": 50,
        "max_search_radius_km": 100
    }'::jsonb)
on conflict (key) do update set value = excluded.value, updated_at = now();

-- 3. Seed Trusted Bangladesh Organizations
insert into public.organizations (name, type, division, district, address, contact_phone, email, is_verified)
values 
    ('Bangladesh Red Crescent Society (National Blood Center)', 'red_crescent', 'Dhaka', 'Dhaka', '7/5 Aurangzeb Road, Mohammadpur, Dhaka 1207', '+88029116563', 'bloodcenter@bdrcs.org', true),
    ('Quantum Foundation Blood Lab', 'ngo', 'Dhaka', 'Dhaka', '119 Shantinagar, Dhaka 1217', '+8801714010869', 'blood@quantummethod.org.bd', true),
    ('Sandhani National Blood Donor Network (DMC Unit)', 'volunteer_club', 'Dhaka', 'Dhaka', 'Dhaka Medical College, Dhaka 1000', '+88029665044', 'sandhanidmc@gmail.com', true),
    ('Badhan (Central Blood Donation Society)', 'volunteer_club', 'Dhaka', 'Dhaka', 'TSC, University of Dhaka, Dhaka 1000', '+88029661900', 'badhancentral@gmail.com', true),
    ('Chittagong Medical College Sandhani Unit', 'volunteer_club', 'Chattogram', 'Chattogram', 'CMC Campus, K.B. Fazlul Kader Road, Chattogram', '+88031619400', 'sandhanicmc@gmail.com', true)
on conflict do nothing;
