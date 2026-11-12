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
