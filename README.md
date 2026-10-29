# adopals

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Xcode Cloud

Xcode Cloud builds the iPhone app and sends it to TestFlight, the same way SAIL and SolidTrack do. Davinder's
merge is the only click before a TestFlight build. Only iOS is built in the cloud; Android is not part of this.

### What the script does

`ios/ci_scripts/ci_post_clone.sh` runs on Xcode Cloud after the clone, before the archive:

1. Installs the Flutter version pinned in `.fvmrc` (3.44.6; git clone of that stable tag into `$HOME/flutter`,
   skipped when that exact version is already on `PATH`), then `flutter precache --ios`.
2. Installs CocoaPods with Homebrew only if it is missing.
3. `flutter pub get` (versions come from the committed `pubspec.lock`).
4. `flutter build ios --config-only --release --build-number=$CI_BUILD_NUMBER`. This writes
   `ios/Flutter/Generated.xcconfig`: version from `pubspec.yaml` (for example 1.0.0), build number from Xcode
   Cloud, so every Xcode Cloud build gets a new build number. Outside Xcode Cloud the pubspec build number is
   used.
5. `pod install` in `ios/` (versions from the committed `ios/Podfile.lock`).

The script reads and writes no secrets. The Firebase client config (`GoogleService-Info.plist`) is already in
the repo. Signing and the upload are done by Xcode Cloud in the workflow's Archive and TestFlight steps.

Pinned versions: Flutter in `.fvmrc`, Dart packages in `pubspec.lock`, pods in `ios/Podfile.lock`, Swift
packages in `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. To move to a
new Flutter version, change `.fvmrc`, run `flutter build ios --config-only` on the Mac and commit what it
migrates, so Xcode Cloud builds exactly what was tested.

### Before the first workflow (Davinder, once)

- An App Store Connect app record must exist first: App Store Connect → Apps → + → New App → iOS, name
  Adopals, bundle ID `com.solidevelectrosoft.adopals`. Xcode Cloud cannot be set up for an app without one.

### Set up the two workflows (Davinder, once)

App Store Connect → Apps → **Adopals** → **Xcode Cloud** → Get Started / Manage Workflows → + (or in Xcode:
open `ios/Runner.xcworkspace` → Product → Xcode Cloud → Create Workflow). Choose product **Runner**.

**Workflow "Develop"**
1. General: Name `Develop`. Description: "develop → internal TestFlight".
2. Environment: Xcode 27.0 (the version used for the local proof) or "Latest Release". Leave "Clean" off.
3. Start Conditions: delete the default condition, add **Branch Changes** → Source Branch → Custom Branches →
   `develop`. Files and Folders: Any file.
4. Actions: delete the default and add **Archive** → Platform **iOS**, Scheme **Runner**, Deployment
   Preparation **TestFlight (Internal Testing Only)**.
5. Post-Actions: + → **TestFlight Internal Testing** → Archive - iOS → add the internal testing group.
6. Save. When Xcode Cloud asks, click **Grant Access** for the GitHub repository `erdavinder2307/adopals`
   (it opens GitHub to install the Xcode Cloud app for that repository only).

**Workflow "Release"**
Same as "Develop", with:
- Name `Release`, description "release/* → TestFlight (App Store candidate)".
- Start Conditions: **Branch Changes** → Custom Branches → **Branch name begins with** `release/`.
- Actions: Archive, iOS, Runner, Deployment Preparation **TestFlight and App Store** (so the build can also be
  picked for App Store review).
- Post-Actions: **TestFlight Internal Testing** → the internal testing group.

No environment variables are needed in either workflow.

### Build number

Xcode Cloud numbers builds with its own counter (`$CI_BUILD_NUMBER`). If any build was ever uploaded to
TestFlight for this app, set the next build number above it: App Store Connect → Adopals → Xcode Cloud →
Settings → Build Number → next build number. Submitting for review stays a manual step.
