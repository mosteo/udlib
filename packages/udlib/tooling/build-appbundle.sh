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
# SYMBOLS_DIR (local disk, one directory per version) and never
# uploaded anywhere. Losing a version's directory costs the ability to
# decode that build's stack traces, and nothing else -- it does not
# affect the build itself, which is why they no longer live on the
# network drive.
#
# The build prints "Warning: The generated ELF library contains
# unobfuscated DWARF debugging information" three times (one per ABI)
# and it is a false alarm on Android specifically: gen_snapshot skips
# --strip on this platform on purpose (Flutter's own build.dart says
# so -- "we let AGP handle stripping of debug symbols"), and AGP does,
# during the Gradle release packaging that runs right after. Verified
# by unzipping a built .aab: every .so under base/lib/ comes out
# `file`-reported as "stripped", with no .debug_* sections in
# `readelf -S`. --obfuscate is doing its job too -- a Dart class name
# added the same day does not show up in `strings` on the resulting
# libapp.so. Nothing here needs --strip added; that flag is for the
# non-Apple-non-Android branch (desktop), which these apps do not
# build for release.
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
  echo ">> symbols at $SYMBOLS (never upload)"
  exit 0
fi

mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/$APP_NAME-$VERSION.aab"
copy_artifact "$LOCAL_AAB" "$OUT"
udlib_print_signer "$OUT"

echo ">> symbols at $SYMBOLS (needed to decode this build's stack"
echo "   traces; never upload them)"
