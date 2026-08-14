#!/usr/bin/env bash
# Build the Play Store release App Bundle (.aab) and copy it out under
# a version-stamped name. Sibling of build-android.sh, whose
# debug-signed sideload path is untouched.
#
# Signing: app/android/upload-keystore.jks + key.properties, both IN
# the app repo and git-crypt encrypted (see its .gitattributes). A
# clone that has not run `git-crypt unlock` sees ciphertext, and the
# Gradle guard refuses to build rather than sign in debug.
# generate-keystore.sh writes both, once.
#
# Without those files the build would be debug-signed and Play rejects
# it, so this script refuses rather than produce a useless artifact.
#
# --split-debug-info writes the Dart symbol maps needed to read a
# future crash report from this exact build. They are archived under
# SYMBOLS_DIR, never uploaded anywhere, and must be KEPT: losing them
# makes that build's stack traces unreadable forever.
#
# Usage: <app>/dev/build-appbundle.sh [extra flutter build args...]
# Env: AAB_OUT_DIR, SYMBOLS_DIR, ENV_FILE, EXPORT_AAB (default 1; set
# to 0 to leave the bundle at Gradle's local output path)

set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
udlib_init

VERSION="$(repo_version)"
OUT_DIR="$(udlib_aab_out_dir)"
SYMBOLS="$(udlib_symbols_dir "$VERSION")"
udlib_build_args "$VERSION"

if [ ! -f "$APP_REPO_ROOT/app/android/key.properties" ]; then
  echo "!! app/android/key.properties missing: the bundle would be" >&2
  echo "   debug-signed and Play rejects it. Run git-crypt unlock," >&2
  echo "   or generate-keystore.sh if the keystore does not exist" >&2
  echo "   yet." >&2
  exit 1
fi

mkdir -p "$SYMBOLS"

cd "$APP_REPO_ROOT/app"
flutter build appbundle --release \
  "${UDLIB_BUILD_ARGS[@]}" "$@" \
  --obfuscate --split-debug-info="$SYMBOLS"

LOCAL_AAB="$APP_REPO_ROOT/app/build/app/outputs/bundle/release/\
app-release.aab"

if [ "${EXPORT_AAB:-1}" = 0 ]; then
  echo ">> $LOCAL_AAB"
  echo ">> symbols archived at $SYMBOLS (keep -- never upload)"
  exit 0
fi

mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/$APP_NAME-$VERSION.aab"
copy_artifact "$LOCAL_AAB" "$OUT"
udlib_print_signer "$OUT"

echo ">> symbols archived at $SYMBOLS (keep: without them this"
echo "   build's stack traces are unreadable forever)"
