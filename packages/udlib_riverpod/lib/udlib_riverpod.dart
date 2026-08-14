/// Riverpod wiring on top of `package:udlib`.
///
/// Kept apart from udlib itself for two reasons, not one. The obvious
/// one is that coldsleep has no state manager -- it uses bare
/// `ValueNotifier` globals -- and must be able to consume the shared
/// code without adopting Riverpod. The less obvious one is
/// dependencies: location lives here, so coldsleep never pulls in
/// geolocator and its native side.
library;

// Phase 2: export 'src/shared_prefs_provider.dart';
// Phase 2: export 'src/locale_provider.dart';
// Phase 5: export 'src/prefs_notifier.dart';
// Phase 5: export 'src/location_provider.dart';
