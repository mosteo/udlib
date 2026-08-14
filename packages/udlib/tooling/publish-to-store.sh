#!/usr/bin/env bash
# One-shot: build the release .aab (reused if one already exists for
# this version) and push it to the app's Play Console tracks.
#
# Usage: <app>/dev/publish-to-store.sh [extra build-appbundle.sh args]
# Env: AAB_OUT_DIR, and TRACKS from the app's app.env

set -euo pipefail

TOOLING="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$TOOLING/lib.sh"
udlib_init

VERSION="$(repo_version)"
OUT_DIR="$(udlib_aab_out_dir)"
AAB="$OUT_DIR/$APP_NAME-$VERSION.aab"
VENV="$APP_REPO_ROOT/admin/.venv"

# Reuse is convenient and is what sanlo and coldsleep have always done,
# but it has a sharp edge: build, then edit code without bumping the
# version, then publish, and the upload is the older bits under the
# same name. birradar has always rebuilt for that reason, so it sets
# REUSE_AAB=0 rather than being quietly converted.
if [ "${REUSE_AAB:-1}" = 1 ] && [ -f "$AAB" ]; then
  echo ">> Reusing $AAB"
else
  AAB_OUT_DIR="$OUT_DIR" "$TOOLING/build-appbundle.sh" "$@"
fi

# The venv lives in the app repo, not in udlib: udlib is fetched into
# pub's cache, which is not somewhere to write build state.
if [ ! -x "$VENV/bin/python3" ]; then
  echo ">> Creating $VENV"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q -r "$TOOLING/requirements-play.txt"
fi

TRACK_ARGS=()
for track in "${TRACKS[@]:-internal}"; do
  TRACK_ARGS+=(--track "$track")
done

# --yes on purpose: these are the app's own testing tracks, opted-in
# testers only, and the next upload just replaces this one. For
# production, call upload_play_release.py directly and answer the
# prompt.
#
# One thing to know about closed tracks (alpha/beta): Play may hold the
# FIRST-EVER push to one for a policy review before testers can install
# it. Internal testing never does, and reruns after that first one
# don't either.
APP_REPO_ROOT="$APP_REPO_ROOT" "$VENV/bin/python3" \
  "$TOOLING/upload_play_release.py" \
  --aab "$AAB" \
  --package-name "$PACKAGE" \
  "${TRACK_ARGS[@]}" \
  --yes
