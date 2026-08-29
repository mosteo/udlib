# Changelog

Shared tooling and code for the Unexpected Developments apps
(coldsleep, birradar, sanlo). When work on one app produces a reusable
improvement, port it here in the same effort and add an entry below, so
the next session working on another app knows it landed. `AGENTS.md`
governs what belongs here.

Versions are git tags; there is no package version bump per release.

## v0.7.1 — 2026-08-29

- `share_plus` bumped to `^13.3.0` (was `^11.1.0`, the version that
  resolves for `udlib` standalone): any app that also depends on
  `geolocator` (sanlo, pilares) needs `win32 ^6.0.0` via
  `package_info_plus`, which conflicts with `share_plus`'s own
  `win32 ^5.5.3` below 13. Pinned in this package rather than left for
  each consuming app to hit and work around.
- `ExternalLinkTile`'s doc comments updated to the current, non-
  deprecated `share_plus` API (`SharePlus.instance.share(ShareParams(
  uri: ...))`) — `Share.share` still works but is deprecated as of
  the version above.

## v0.7.0 — 2026-08-29

- `ExternalLinkTile` (`package:udlib`): a `ListTile`-shaped row that
  opens a URL on tap and adds a share button (the OS share sheet, via
  `share_plus`) and a QR button (shows the link as a QR code, via
  `qr_flutter`) to its trailing edge. First real Dart export from this
  package — lands ahead of AGENTS.md's usual "already in two apps"
  bar by explicit request, built for Pilares' external-link rows
  (official programme, Play Store listing, privacy policy, poster
  gallery attribution).

## v0.6.0 — 2026-08-28

- `tooling/test.sh`: run an app's Flutter test suite with no manual
  environment setup — `udlib_init` puts Flutter on PATH exactly as the
  build scripts do. Arguments pass through to `flutter test`. The app
  wrapper is three lines, like `build-appbundle.sh`. Ported from
  coldsleep.
- `tooling/bump-version.sh --major|--minor|--patch`: rewrite
  `app/pubspec.yaml`'s version, always incrementing the build number
  (`+N`) in lockstep with the semver part — Play rejects a re-used
  versionCode. Does not go through `udlib_init` (text edit only), like
  `generate-keystore.sh`. Ported from coldsleep.

## v0.5.1 — 2026-08-26

- Debug symbol maps archive to `~/tmp/android-symbols/<app>/<version>`
  instead of the network drive. `SYMBOLS_DIR` still works as an
  override.

## v0.5.0 — 2026-08-25

- `upload_play_release.py`: a failed upload no longer prints a
  reassuring `Status: completed` after the real error (stdout
  line-buffering plus a relabeled release-state line).
- Housekeeping: stray `.pyc` removed and ignored; README/AGENTS
  reorganized.

## v0.4.0 — 2026-08-15

- `app.env` template documents `SUFFIX` and `REUSE_AAB`, for
  birradar's two real differences from the other apps.

## v0.3.0 — 2026-08-15

- Absorb the build knowledge that had been stranded in sanlo's
  comments.

## v0.2.0 — 2026-08-15

- Shared release tooling: one copy of the build/publish scripts, the
  Gradle guard and the CI workflow, consumed on the same git pin as
  the Dart code.

## v0.1.0 — 2026-08-15

- Bootstrap: two packages, shared lints, own CI. Empty but green.
