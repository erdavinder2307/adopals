# Samsung Galaxy Store build — Adopals

The Galaxy Store APK is the normal Android release build. Adopals has no in-app purchase, subscription or paywall
code and no Play-only APIs (no Play Billing, in-app review, Play Integrity or Play Core), so it needs **no
`STORE=galaxy` define**: the free experience is the only one the app has.

## Build

```bash
fvm flutter build apk --release      # Flutter 3.44.6, the .fvmrc pin
# -> build/app/outputs/flutter-apk/app-release.apk
```

- Flutter 3.44.6 needs Gradle ≥ 8.7, so this branch moves the Android toolchain to Gradle 8.12, Android Gradle
  Plugin 8.7.3 and Kotlin 2.2.20, and keeps the two flags its migrator adds to `android/gradle.properties`
  (`android.builtInKotlin=false`, `android.newDsl=false`). Flutter warns that Gradle 8.14 / AGP 8.11.1 will be the
  minimum soon; the build works today.
- The app name on the launcher is now "Adopals" (was "adopals").

### Signing

`android/app/build.gradle` reads `android/key.properties` (keyAlias, keyPassword, storeFile, storePassword; ignored by
git). **Adopals has no release keystore yet.** Without `key.properties` the release build falls back to the debug key:
it builds, but that APK must not be uploaded (a Galaxy Store app can never change its signing key later). Create the
keystore once, back it up with its password, and keep both outside git:

```bash
keytool -genkey -v -keystore adopals-release.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Check the signer before uploading: `apksigner verify --print-certs app-release.apk` must not show `CN=Android Debug`.

### Google sign-in on Android

Google sign-in on Android only works when the SHA-1 of the signing key is registered for the Android app
`com.solidevelectrosoft.adopals` in Firebase, and `android/app/google-services.json` is downloaded again afterwards
(today it has no Android OAuth client for this package). Do this right after creating the release keystore:

```bash
keytool -list -v -keystore adopals-release.jks -alias upload | grep SHA1
```

Email sign-in does not depend on it. Sign in with Apple is shown on iOS only.

## Version and SDK

| Item | Value | Source |
|------|-------|--------|
| versionName / versionCode | 1.0.0 / 1 (`version: 1.0.0+1`) | `pubspec.yaml`; bump there before each upload |
| applicationId | `com.solidevelectrosoft.adopals` | `android/app/build.gradle` |
| minSdk | 24 | Flutter 3.44.6 raises the configured 23 to 24 |
| targetSdk / compileSdk | 36 / 36 | Flutter 3.44.6 defaults |
| Size | 59.5 MB (universal APK) | 30 Oct build |

## Permissions (from the built APK, `aapt2 dump badging`)

| Permission | From | Why |
|------------|------|-----|
| `android.permission.INTERNET` | Firebase | sign-in, pet listings, adoption requests |
| `android.permission.ACCESS_NETWORK_STATE` | Firebase | connectivity checks |
| `com.google.android.providers.gsf.permission.READ_GSERVICES` | Google sign-in / Play services | Google account sign-in |
| `com.solidevelectrosoft.adopals.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX (generated) | internal, not shown to users |

No location, camera, contacts, SMS, storage, notification or advertising-ID permissions.

## Galaxy Store listing inputs

- Category: Lifestyle (pet adoption).
- Age rating: users publish pet listings and send adoption requests to each other (user-generated content and
  user-to-user contact; report and block come with the separate user-safety change). No ads, no location, no in-app purchases.
- Accounts are created in the app (email or Google).
