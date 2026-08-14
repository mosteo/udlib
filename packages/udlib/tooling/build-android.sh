#!/usr/bin/env bash
# Build the release APK -- a debug-signed sideload build, no Play Store
# involved, purely for testing on a real phone -- and copy it out under
# a version-stamped name.
#
# Release rather than debug on purpose: these apps are tested by
# installing release APKs on a real device, which is also why coldsleep
# gates its dev affordances on a plain constant instead of kDebugMode.
#
# Usage: <app>/dev/build-android.sh [extra flutter build args...]
# Env: APK_OUT_DIR, ENV_FILE, SUFFIX (appended to the APK name, to keep
# variant builds apart -- e.g. SUFFIX=-tiles dev/build-android.sh
# --dart-define=DISCOVERY=tiles)

set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
udlib_init

VERSION="$(repo_version)"
OUT_DIR="$(udlib_apk_out_dir)"
udlib_build_args "$VERSION"

cd "$APP_REPO_ROOT/app"
flutter build apk --release \
  "${UDLIB_BUILD_ARGS[@]}" "$@"

mkdir -p "$OUT_DIR"
copy_artifact build/app/outputs/flutter-apk/app-release.apk \
  "$OUT_DIR/$APP_NAME-$VERSION${SUFFIX:-}.apk"
