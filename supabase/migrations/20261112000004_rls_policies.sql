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
