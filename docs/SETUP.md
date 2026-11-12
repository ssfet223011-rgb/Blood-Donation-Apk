# BloodBond Bangladesh — Local Setup & Development Guide

## Prerequisites

Ensure you have the following installed:
- Flutter SDK (v3.22+ or latest stable)
- Java Development Kit (JDK 17)
- Android Studio / Android SDK (API 34)
- Git
- Supabase CLI or Supabase Cloud Account

---

## Step-by-Step Installation

### 1. Clone the Repository
```bash
git clone https://github.com/bloodbond/bloodbond-bangladesh.git
cd bloodbond-bangladesh
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Fill in your `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

### 3. Deploy Database Migrations
Deploy the PostgreSQL migrations located in `supabase/migrations/` to your Supabase instance:
```bash
supabase db push
```

### 4. Install Dependencies
```bash
flutter pub get
```

### 5. Run the Application
```bash
# Run in debug mode on connected device or emulator
flutter run
```

### 6. Run the Admin Panel
```bash
python -m http.server 8080 --directory admin_panel
```
Access the admin portal at `http://localhost:8080`.
