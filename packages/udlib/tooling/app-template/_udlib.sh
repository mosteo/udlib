# Locate the udlib checkout that pub already pinned. Sourced, not run.
#
# Copy this file to <app>/dev/_udlib.sh. It is the one piece that
# cannot itself come from udlib -- something has to find udlib first.
#
# The lookup goes through app/.dart_tool/package_config.json, a
# documented format that `pub get` writes, rather than guessing a path
# inside pub's cache (whose layout is not a stable contract). The
# payoff is that one pin -- the git ref in pubspec.yaml -- covers both
# the Dart code and these scripts, so they cannot fall out of step.

udlib_tooling() {  # $1 = app repo root
  python3 - "$1" <<'PY'
import json, pathlib, sys, urllib.parse

cfg = pathlib.Path(sys.argv[1]) / 'app' / '.dart_tool' / \
    'package_config.json'
if not cfg.is_file():
    sys.exit(f'!! {cfg} not found: run `flutter pub get` in app/ first')

for pkg in json.loads(cfg.read_text())['packages']:
    if pkg['name'] == 'udlib':
        # rootUri is absolute for a git dependency and relative to
        # .dart_tool/ for a path one. Resolving against cfg.parent
        # handles both without caring which is in use.
        root = urllib.parse.unquote(
            urllib.parse.urlparse(pkg['rootUri']).path)
        tooling = (cfg.parent / root).resolve() / 'tooling'
        if not tooling.is_dir():
            sys.exit(f'!! udlib resolved to {tooling}, which does not '
                     'exist: the pinned ref predates the shared '
                     'tooling')
        print(tooling)
        break
else:
    sys.exit('!! udlib is not a dependency of this app: add it to '
             'app/pubspec.yaml and run `flutter pub get`')
PY
}
