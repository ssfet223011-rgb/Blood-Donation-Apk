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
