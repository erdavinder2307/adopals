#!/bin/bash
# Xcode Cloud runs this after cloning the repo, before it resolves packages and archives the Runner scheme.
# It installs the Flutter version pinned in .fvmrc, fetches packages, writes ios/Flutter/Generated.xcconfig
# with the Xcode Cloud build number, and runs `pod install`. Nothing here signs or uploads: Xcode Cloud does
# that in the workflow's Archive and TestFlight steps. No secrets are read or written.
# Setup and the two workflows: README.md, section "Xcode Cloud".
set -euo pipefail

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

REPO_DIR="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_DIR"

# --- Flutter (pinned to .fvmrc, same version the Mac uses through fvm) -------------------------------
# The Flutter 3.44 iOS migrations (Swift Package Manager integration, UIScene lifecycle) are committed, so
# `flutter build ios --config-only` below does not rewrite tracked project files in this checkout.
FLUTTER_VERSION="$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc 2>/dev/null || true)"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.6}"

flutter_matches() {
  command -v flutter >/dev/null 2>&1 &&
    flutter --version --machine 2>/dev/null | grep -qF "\"frameworkVersion\": \"$FLUTTER_VERSION\""
}

if flutter_matches; then
  echo "Flutter $FLUTTER_VERSION already on PATH ($(command -v flutter)); not installing."
else
  # Where Flutter is cloned when the pinned version is not already on PATH (a path under $HOME).
  FLUTTER_HOME="${FLUTTER_INSTALL_DIR:-$HOME/flutter}"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 --branch "$FLUTTER_VERSION" "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
  flutter_matches || { echo "error: $FLUTTER_HOME is not Flutter $FLUTTER_VERSION"; exit 1; }
fi
flutter config --no-analytics >/dev/null
flutter precache --ios

# --- CocoaPods ----------------------------------------------------------------------------------------
# flutter_secure_storage and sign_in_with_apple still use CocoaPods (the other plugins use Swift Package
# Manager). Installed before `flutter build ios --config-only`, which runs `pod install` itself and fails
# on a fresh clone when CocoaPods is missing.
if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

# pubspec.lock is committed, so this resolves the same package versions every build.
flutter pub get

# --- Build number -------------------------------------------------------------------------------------
# Release config only (no build): writes FLUTTER_BUILD_NAME (pubspec version) and FLUTTER_BUILD_NUMBER
# into Generated.xcconfig; Runner/Info.plist reads both. On Xcode Cloud the build number is
# $CI_BUILD_NUMBER, so every upload is new. Outside Xcode Cloud the pubspec build number is used.
if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  BUILD_NUMBER="$CI_BUILD_NUMBER"
  echo "Build number: $BUILD_NUMBER (Xcode Cloud)."
else
  BUILD_NUMBER="$(sed -n 's/^version:[[:space:]]*[^+]*+\([0-9]*\).*/\1/p' pubspec.yaml)"
  BUILD_NUMBER="${BUILD_NUMBER:-1}"
  echo "Build number: $BUILD_NUMBER (pubspec.yaml; CI_BUILD_NUMBER not set)."
fi
flutter build ios --config-only --release --build-number="$BUILD_NUMBER"

# --- pod install --------------------------------------------------------------------------------------
# Again so the Pods match this checkout and the committed Podfile.lock (config-only already ran it once).
# The Podfile post_install raises every pod to iOS 15.0, because Xcode 27 rejects deployment targets
# below 15.
cd ios
pod install
