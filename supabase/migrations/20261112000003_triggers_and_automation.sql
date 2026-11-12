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
