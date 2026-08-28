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
single app today are noted as candidates and wait their turn. This bar
is about app *code*; `tooling/` is shared infrastructure by nature, so
a genuinely app-agnostic dev script (it takes `APP_REPO_ROOT`, reads
`app.env`, hardcodes nothing) is added here directly.

**Reusable improvements flow back here in the same effort, not
later.** When work on one app produces something the others want — a
new `dev/` script, a fix to shared tooling — port it now: cut a tag,
bump the app's `ref:`, reduce its `dev/` script to a wrapper. Add a
`CHANGELOG.md` entry for every ported change, so the next session on
another app knows it exists.

**Some things look generic and are not.** coldsleep's `class Ui` reads
like a design-token file but is the visual identity of one retro app,
with contrast ratios measured against its own background. sanlo's
`festivalDayRolloverHour = 6` is Huesca folk knowledge, not a date
utility. birradar's `VenueCache` is not an LRU, it is beer-price
domain logic. These stay where they are.
