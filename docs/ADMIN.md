# BloodBond Bangladesh — Administrative & Moderation Manual

## 1. Role Hierarchy

```text
SUPER_ADMIN    - Full database access, configuration, key rotation, system audits
ADMIN          - User moderation, donor verification, organization approval
MODERATOR      - Review moderation, spam dispute resolution, report investigation
ORGANIZATION   - Verified blood banks & hospitals (issue donation certificates)
VOLUNTEER      - Regional coordinators managing local drives and verifying donors
```

---

## 2. Verification Protocol for Donations

1. Log into the BloodBond Admin Portal (`admin_panel/`).
2. Navigate to **Donation Verification** tab.
3. Cross-reference the uploaded hospital blood requisition slip or phlebotomy certificate.
4. Verify:
   - Donor ID and Name
   - Hospital / Blood Bank Name
   - Donation Date (Must not conflict with active rest periods)
   - Component Type (Whole blood, platelets, plasma)
5. Click **Approve & Verify**.
6. System will:
   - Recalculate official donation total.
   - Upgrade badge if milestone reached (`verified_donor`, `star_donor`, `blood_champion`, `legend`).
   - Transition donor availability to `temporarily_unavailable` for 90 days.
   - Record immutable entry in `audit_logs`.
