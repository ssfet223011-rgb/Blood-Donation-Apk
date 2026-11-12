# BloodBond Bangladesh — Admin Panel

The BloodBond Bangladesh Admin Panel is a responsive web application designed for national administrators, medical coordinators, and regional moderators.

## Capabilities

1. **National Command Overview**:
   - Total users, verified donors, and live available donor metrics.
   - Emergency blood request radar with 5km proximity dispatch.
   - Real-time blood group inventory distribution.

2. **Donor Registry & Moderation**:
   - Filter donors by Division, District, Upazila, Blood Group, and Availability.
   - Inspect donor records while preserving contact privacy.
   - Flag accounts and manage verification badges (`verified_donor`, `star_donor`, `blood_champion`, `legend`).

3. **Donation Verification Workflow**:
   - Audit hospital blood donation certificates and slips.
   - Trigger official verified donation increments.
   - Enforce 90-day cooldown and automated rest periods.

4. **Security & Audit Logs**:
   - Immutable audit trail recording user verification, role changes, contact approvals, and emergency broadcasts.

## Running Locally

Simply serve with any HTTP server:

```bash
# Using python
python -m http.server 8080

# Using Node.js npx
npx serve admin_panel
```

Or deploy directly to Vercel, Netlify, or Supabase Storage Hosting.
