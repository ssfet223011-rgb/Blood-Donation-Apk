# BloodBond Bangladesh — Quality Assurance & Testing Framework

## 1. Test Suite Architecture

The platform includes comprehensive test suites across:
1. **Unit Tests**:
   - Blood compatibility logic (`is_blood_compatible`).
   - Donor ID generator validation (`BB-XXX-000000`).
   - Availability transition rules (90-day cooldown calculation).
   - Distance calculation and tier classification (<=5km, 5-20km, 20-50km).
2. **State & Provider Tests**:
   - Riverpod `AuthStateNotifier` state transitions (`unauthenticated`, `authenticated`, `profile_incomplete`).
   - `DonorSearchNotifier` pagination and filters.
   - `BloodRequestNotifier` emergency dispatch.
3. **Security & RLS Tests**:
   - Unauthorized access blocked when reading raw donor phone numbers.
   - Preventing seekers from updating another user's blood request.
   - Exact coordinates isolation.
4. **Integration & Journey Tests**:
   - End-to-end Donor Onboarding → ID Generation → Verification → Availability Review.
   - End-to-end Seeker Discovery → 2-Way Consent Handshake → Request Completion → Review.

---

## 2. Running the Test Suite

```bash
# Run all Flutter unit and widget tests
flutter test

# Run tests with code coverage report
flutter test --coverage

# Run database tests with pgTAP (Supabase)
supabase test db
```
