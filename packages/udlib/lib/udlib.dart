/// Shared Flutter code for the Unexpected Developments apps.
///
/// This is the barrel: apps import `package:udlib/udlib.dart` and get
/// everything. Individual libraries stay importable on their own for
/// anyone who wants a narrower dependency.
///
/// The rest is still empty -- extraction lands one phase at a time,
/// and a phase is only merged once the app it came from passes its
/// own unmodified test suite against this package. `ExternalLinkTile`
/// is the one exception so far: new code, not an extraction, landed
/// ahead of the usual "already in two apps" bar by explicit request
/// (see AGENTS.md and its own doc comment).
library;

export 'src/widgets/external_link_tile.dart';

// Phase 2: export 'src/l10n/framework_fallbacks.dart';
// Phase 2: export 'src/l10n/locale_store.dart';
// Phase 3: export 'src/error_log/app_error_log.dart';
// Phase 3: export 'src/error_log/error_log_screen.dart';
// Phase 4: export 'src/changelog/changelog.dart';
// Phase 5: export 'src/prefs/stores.dart';
// Phase 5: export 'src/text/search.dart';
