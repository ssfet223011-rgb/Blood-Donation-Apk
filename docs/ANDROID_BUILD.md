# BloodBond Bangladesh — Android Production Build & Release Guide

## 1. Application Identifier & Configuration

- **Application ID**: `com.bloodbond.bangladesh`
- **Minimum SDK**: 23 (Android 6.0 Marshmallow)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34
- **Java Compatibility**: Version 17

---

## 2. Production Permissions Configuration

In `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.bloodbond.bangladesh">

    <!-- Minimal required network permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <!-- Notifications for emergency alerts -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <!-- Location permissions for nearby 5km donor discovery -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <!-- Camera for scanning Digital Donor ID QR codes -->
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-permission android:name="android.permission.CAMERA"/>

    <!-- Storage not needed in Android 13+ (Uses Photo Picker) -->
</manifest>
```

---

## 3. Release Keystore Generation

Generate your production signing key using JDK `keytool`:

```bash
keytool -genkey -v -keystore bloodbond-release.keystore -alias bloodbond -keyalg RSA -keysize 2048 -validity 10000
```

Create `android/key.properties` (added to `.gitignore`):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=bloodbond
storeFile=../bloodbond-release.keystore
```

---

## 4. Build Commands

```bash
# Clean project
flutter clean
flutter pub get

# 1. Build Debug APK
flutter build apk --debug

# 2. Build Production Release APK (Universal)
flutter build apk --release

# 3. Build Split Release APKs per ABI (arm64-v8a, armeabi-v7a, x86_64)
flutter build apk --release --split-per-abi

# 4. Build Google Play Production App Bundle (.aab)
flutter build appbundle --release
```
