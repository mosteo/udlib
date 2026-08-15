# udlib

Shared code and release tooling for the UnexpecteDevelopments apps.

## Layout

```
packages/udlib/            Flutter, no Riverpod.
packages/udlib/tooling/    Release scripts, CI workflow, Gradle guard.
packages/udlib_riverpod/   Riverpod wiring.
```

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