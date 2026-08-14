# Common to the shared build scripts. Sourced, not executed.
#
# The contract: the app's thin wrapper exports APP_REPO_ROOT and calls
# udlib_init, which puts Flutter on PATH and loads the app's app.env.
# Everything app-specific lives in that one file.

# Fail loudly on the mistakes that are otherwise silent.
udlib_init() {
  if [ -z "${APP_REPO_ROOT:-}" ]; then
    echo "!! APP_REPO_ROOT unset: call this through the app's dev/" >&2
    echo "   wrapper, which exports it." >&2
    return 1
  fi

  # Same location in all three apps, and the reason the scripts set it
  # themselves rather than relying on the caller's shell: a build must
  # not depend on which terminal it was started from.
  export PATH="$HOME/opt/flutter/bin:$PATH"

  if [ ! -f "$APP_REPO_ROOT/app.env" ]; then
    echo "!! $APP_REPO_ROOT/app.env not found." >&2
    echo "   It holds APP_NAME, PACKAGE and the build arguments that" >&2
    echo "   are specific to this app. See udlib's README." >&2
    return 1
  fi
  # shellcheck source=/dev/null
  . "$APP_REPO_ROOT/app.env"

  : "${APP_NAME:?app.env must set APP_NAME}"
  : "${PACKAGE:?app.env must set PACKAGE}"
}

# Where the sideload APK goes: the rclone mount, so the phone or
# another machine can fetch it.
udlib_apk_out_dir() {
  echo "${APK_OUT_DIR:-$HOME/cloud/ORIG/drive/JANO/tmp}"
}

# Where the .aab goes -- deliberately NOT the rclone mount that the APK
# uses. Nobody fetches a bundle by hand; its destination is Play, and
# publish-to-store.sh reads it straight back to upload it. That
# read-back is exactly what corrupted a bundle on sanlo, and the mount
# has since returned I/O errors on a plain `ls`. copy_artifact would
# catch a bad write, but the cheaper fix is not writing it there.
udlib_aab_out_dir() {
  echo "${AAB_OUT_DIR:-$HOME/.cache/$APP_NAME-builds}"
}

# Dart symbol maps for de-symbolicating a future crash report from one
# exact build. Archived, NEVER uploaded, and must be kept: losing them
# makes that build's Dart stack traces unreadable forever.
udlib_symbols_dir() {  # $1 = version
  echo "${SYMBOLS_DIR:-\
$HOME/cloud/ORIG/drive/JANO/$APP_NAME-symbols/$1}"
}

# Semver only: pubspec's build number (+N) is a store detail, not part
# of the name testers see.
repo_version() {
  grep '^version:' "$APP_REPO_ROOT/app/pubspec.yaml" \
    | sed -E 's/^version:\s*([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
}

# The flutter build arguments every app shares, assembled from app.env.
# Result lands in the UDLIB_BUILD_ARGS array; bash cannot return one.
#
# ENV_FILE stays an environment override rather than being folded into
# BUILD_ARGS, because birradar switches it per build
# (`ENV_FILE=env/local.json dev/build-appbundle.sh`).
udlib_build_args() {  # $1 = version
  UDLIB_BUILD_ARGS=()

  if [ -n "${ENV_FILE:-}" ]; then
    UDLIB_BUILD_ARGS+=(
      --dart-define-from-file="$APP_REPO_ROOT/$ENV_FILE"
    )
  fi

  # coldsleep reads its version at runtime from this define; birradar
  # and sanlo keep a const in version.dart instead. Opt-in per app so
  # migrating changes nothing about what each build produces.
  if [ "${VERSION_VIA_DART_DEFINE:-0}" = 1 ]; then
    UDLIB_BUILD_ARGS+=(--dart-define=APP_VERSION="$1")
  fi

  # The +"..." form, not "${BUILD_ARGS[@]-}": the latter expands an
  # unset array to one empty string, which flutter then sees as an
  # empty argument and rejects.
  UDLIB_BUILD_ARGS+=("${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"}")
}

# Copy a build artifact out and prove the copy is intact.
#
# Two checks, because they catch different things: unzip -t verifies
# every entry's CRC, and the checksum comparison catches anything that
# survived that. Both APKs and app bundles are ZIPs, so both apply.
#
# This exists because sanlo hit real silent corruption writing a large
# file to the rclone mount and reading it straight back: a valid-looking
# .aab that Play rejected as an invalid ZIP, while a local copy of the
# same build was fine. The risk is not avoided here, it is made
# impossible to miss.
copy_artifact() {  # $1 = built file, $2 = destination path
  local src="$1" dest="$2"
  cp "$src" "$dest"

  if ! unzip -tqq "$dest" >/dev/null 2>&1; then
    echo "!! $dest is not a valid ZIP: corrupt write." >&2
    return 1
  fi

  local a b
  a="$(md5sum < "$src" | cut -d' ' -f1)"
  b="$(md5sum < "$dest" | cut -d' ' -f1)"
  if [ "$a" != "$b" ]; then
    echo "!! $dest does not match the original ($a vs $b)." >&2
    echo "   Silent corruption on write. Repeat the copy." >&2
    return 1
  fi

  echo ">> $dest"
}

# Name the signer of a bundle or APK.
#
# A debug-signed release is the one failure that looks like success
# until Play refuses the upload, so it gets said out loud.
udlib_print_signer() {  # $1 = .aab or .apk
  command -v keytool >/dev/null 2>&1 || return 0
  echo ">> Signed by:"
  unzip -p "$1" 'META-INF/*.RSA' 2>/dev/null \
    | keytool -printcert 2>/dev/null \
    | grep -m2 -E 'Owner|Valid|Propietario|Válido' \
    | sed 's/^/   /' || echo "   (could not read the certificate)"
}
