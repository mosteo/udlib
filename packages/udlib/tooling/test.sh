#!/usr/bin/env bash
# Run the app's Flutter test suite with no manual environment setup:
# udlib_init puts Flutter on PATH the same way the build scripts do,
# so `dev/test.sh` works from any shell and any directory.
#
# Every argument passes straight through to `flutter test`, e.g.
#   <app>/dev/test.sh test/daily_test.dart --name singladura
#
# Usage: <app>/dev/test.sh [flutter test args...]

set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
udlib_init

cd "$APP_REPO_ROOT/app"
exec flutter test "$@"
