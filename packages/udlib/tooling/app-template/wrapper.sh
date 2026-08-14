#!/usr/bin/env bash
# TEMPLATE. Copy to <app>/dev/<name>.sh and change the last line to
# name the udlib script it forwards to.
#
# Everything an app keeps of a build script is this: where the repo is,
# and which shared script to run. The rest lives in udlib and in
# app.env.

set -euo pipefail

export APP_REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$APP_REPO_ROOT/dev/_udlib.sh"

# Assigned rather than inlined into exec: with `set -e` a failing
# command substitution aborts here, which is what should happen when
# udlib cannot be resolved. Inlined, the error message would be
# swallowed and exec would fail with a confusing empty path.
UDLIB_TOOLING="$(udlib_tooling "$APP_REPO_ROOT")"

exec "$UDLIB_TOOLING/build-appbundle.sh" "$@"
