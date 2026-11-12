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
