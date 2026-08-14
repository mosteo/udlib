#!/usr/bin/env bash
# Generate the app's upload keystore + key.properties, one time.
# Both land under app/android/ on paths that are git-crypt encrypted
# (see the app's .gitattributes) -- committing them stores ciphertext,
# recoverable by anyone who can `git-crypt unlock` with the GPG key
# added as a collaborator. There is deliberately no separate backup
# step: the GPG key is the durable anchor.
#
# Usage: <app>/dev/generate-keystore.sh
# Refuses to run if git-crypt isn't initialized/unlocked, so the
# keystore can never accidentally be committed in the clear.
#
# Note this one does not go through udlib_init: it can legitimately be
# the first thing run in a fresh app repo, before app.env exists.

set -euo pipefail

if [ -z "${APP_REPO_ROOT:-}" ]; then
  echo "!! APP_REPO_ROOT unset: call this through the app's dev/" >&2
  echo "   wrapper, which exports it." >&2
  exit 1
fi

ANDROID_DIR="$APP_REPO_ROOT/app/android"
KEYSTORE_PATH="$ANDROID_DIR/upload-keystore.jks"
PROPS_PATH="$ANDROID_DIR/key.properties"
ALIAS=upload

cd "$APP_REPO_ROOT"

if ! command -v git-crypt >/dev/null; then
  echo "error: git-crypt not found on PATH" >&2
  exit 1
fi

if ! git-crypt status >/dev/null 2>&1; then
  echo "error: this is not a git-crypt repo (run git-crypt init" \
    "first)" >&2
  exit 1
fi

# Not just "is this a git-crypt repo" but "is THIS path actually
# covered": the .gitattributes scopes exact paths rather than a broad
# *.jks, so a typo there would otherwise mean a keystore committed in
# the clear.
FILTER="$(git check-attr filter -- "$PROPS_PATH" | \
  sed 's/.*filter: //')"
if [ "$FILTER" != "git-crypt" ]; then
  echo "error: $PROPS_PATH is not covered by git-crypt (check" \
    "the repo-root .gitattributes)" >&2
  exit 1
fi

if [ -f "$KEYSTORE_PATH" ]; then
  echo "error: $KEYSTORE_PATH already exists -- refusing to" \
    "overwrite an existing upload keystore" >&2
  exit 1
fi

echo "Generating the app's upload keystore."
echo "You'll be asked for a store password, a key password (can" \
  "be the same), and your name/org details for the certificate."
echo

read -r -s -p "Store password: " STORE_PASSWORD
echo
read -r -s -p "Key password (blank = same as store password): " \
  KEY_PASSWORD
echo
KEY_PASSWORD="${KEY_PASSWORD:-$STORE_PASSWORD}"

read -r -p "Your name (CN, e.g. 'Alejandro Mosteo'): " CN
read -r -p "Organization (O, blank ok): " O
read -r -p "City (L, blank ok): " L
read -r -p "Country code (C, e.g. ES): " C

DNAME="CN=$CN"
[ -n "$O" ] && DNAME="$DNAME, O=$O"
[ -n "$L" ] && DNAME="$DNAME, L=$L"
[ -n "$C" ] && DNAME="$DNAME, C=$C"

keytool -genkeypair -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$STORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "$DNAME"

cat >"$PROPS_PATH" <<EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$ALIAS
storeFile=upload-keystore.jks
EOF

echo
echo "Wrote $KEYSTORE_PATH and $PROPS_PATH."
echo "Both are git-crypt encrypted paths: 'git add' + commit" \
  "them normally, the repo stores ciphertext. Recovery anchor" \
  "is your GPG key (the git-crypt collaborator) -- nothing else" \
  "to back up separately."
