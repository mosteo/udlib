# udlib

Shared code and release tooling for the Unexpected Developments
Flutter apps: **birradar**, **sanlo** and **coldsleep**.

The three are separate repos by the same author, and they had grown
the same code three times over. That was not a hypothetical: when this
repo was created, `admin/generate-keystore.sh` was byte-identical
between sanlo and coldsleep, `l10n_fallback.dart` was the same code in
birradar and coldsleep with only the comment differing, and
`app_error_log.dart` differed by 11 lines out of 65 between birradar
and sanlo.

The cost was already visible, and it was not redundancy — it was
**improvements stranded in separate copies**. `upload_play_release.py`
existed three times: birradar's had a repeatable `--track` for
multi-track uploads, sanlo's and coldsleep's had
`--send-for-review`, and no copy had both. This repo is where that
stops.

## Layout

```
packages/udlib/            Flutter, no Riverpod. All three apps.
packages/udlib/tooling/    Release scripts, CI workflow, Gradle guard.
packages/udlib_riverpod/   Riverpod wiring. birradar and sanlo only.
```

The split is not only about Riverpod. coldsleep uses bare
`ValueNotifier` globals and must be able to consume the shared code
without adopting a state manager — but the split also keeps
`geolocator` and anything else with a native side out of `udlib`, so
coldsleep never pulls in dependencies it has no use for.

## How apps consume this

A git dependency pinned to a ref, so a change here cannot break three
apps at once:

```yaml
dependencies:
  udlib:
    git:
      url: git@github.com:<user>/udlib.git
      ref: v0.1.0
      path: packages/udlib
```

The **non-Dart tooling travels on the same pin**. Rather than guessing
a path inside pub's cache, each app resolves it through
`app/.dart_tool/package_config.json` — a documented format that
`pub get` writes — via a small `dev/_udlib.sh`. One pin covers the
code and the scripts, so they cannot fall out of step.

Per-app configuration is one file, `app.env`, holding the package
name, the Play tracks, the output directories and the dart-defines.
Everything else about a release is shared.

## Rules

**Everything here is in English** — Dart, comments, doc comments,
tooling, error messages and Markdown. No exceptions. The apps keep
their own language; sanlo targets the Spanish market and uses Spanish
in parts of its code and docs, and that does not change. When code
moves in from coldsleep, its Spanish comments are translated, and the
*reasoning* is translated, not just the sentence: those comments are
worth having precisely because they explain why.

**Only code that already exists in two or more of the apps comes
here.** Extraction must not change behaviour: after an app migrates,
its own unmodified test suite is the proof. Things that live in a
single app today are noted as candidates and wait their turn.

**Some things look generic and are not.** coldsleep's `class Ui` reads
like a design-token file but is the visual identity of one retro app,
with contrast ratios measured against its own background. sanlo's
`festivalDayRolloverHour = 6` is Huesca folk knowledge, not a date
utility. birradar's `VenueCache` is not an LRU, it is beer-price
domain logic. These stay where they are.
