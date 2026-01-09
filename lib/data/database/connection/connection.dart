import 'package:drift/drift.dart';

/// Opens a database connection.
///
/// This stub is replaced by platform-specific implementations:
/// - native.dart for mobile/desktop (iOS, Android, macOS, Linux, Windows)
/// - web.dart for web builds
QueryExecutor openConnection() {
  throw UnsupportedError(
    'No suitable database implementation was found on this platform.',
  );
}
