import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens a web database connection.
///
/// Uses drift_flutter's driftDatabase which automatically handles
/// WASM setup and IndexedDB storage for web platforms.
QueryExecutor openConnection() {
  return driftDatabase(
    name: 'red_letter_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
