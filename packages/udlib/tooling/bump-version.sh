#!/usr/bin/env bash
# Bump the version line in <app>/app/pubspec.yaml.
#
# The build number (+N) always goes up by one, whichever semver part
# moves: every release across these apps has bumped both in lockstep,
# and Play rejects a re-used versionCode.
#
#   --major   X.Y.Z+N  ->  (X+1).0.0+(N+1)
#   --minor   X.Y.Z+N  ->  X.(Y+1).0+(N+1)
#   --patch   X.Y.Z+N  ->  X.Y.(Z+1)+(N+1)
#
# Usage: <app>/dev/bump-version.sh --major | --minor | --patch
#
# Like generate-keystore.sh, this does not go through udlib_init: it
# only rewrites one line of a text file and needs neither Flutter nor
# app.env, just APP_REPO_ROOT from the wrapper.

set -euo pipefail

if [ -z "${APP_REPO_ROOT:-}" ]; then
  echo "!! APP_REPO_ROOT unset: call this through the app's dev/" >&2
  echo "   wrapper, which exports it." >&2
  exit 1
fi

case "${1:-}" in
  --major) part=major ;;
  --minor) part=minor ;;
  --patch) part=patch ;;
  *)
    echo "usage: dev/bump-version.sh --major | --minor | --patch" >&2
    exit 2
    ;;
esac

pubspec="$APP_REPO_ROOT/app/pubspec.yaml"

line="$(grep -E '^version:[[:space:]]*[0-9]' "$pubspec" || true)"
if [ -z "$line" ]; then
  echo "!! no 'version: X.Y.Z+N' line in $pubspec" >&2
  exit 1
fi

cur="${line#version:}"
cur="${cur//[[:space:]]/}"
if [[ "$cur" != *.*.*+* ]]; then
  echo "!! version '$cur' is not X.Y.Z+N" >&2
  exit 1
fi

semver="${cur%%+*}"
build="${cur##*+}"
IFS=. read -r major minor patch <<EOF
$semver
EOF

case "$part" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac

new="$major.$minor.$patch+$((build + 1))"
sed -i -E "s/^version:[[:space:]]*.*/version: $new/" "$pubspec"

echo ">> $cur -> $new"
