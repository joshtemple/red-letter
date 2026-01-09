import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Opens a native database connection for mobile and desktop platforms.
///
/// Uses NativeDatabase (FFI-based SQLite) with the database file
/// stored in the application documents directory.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'red_letter.db'));

    if (Platform.isMacOS || Platform.isIOS) {
      print('📱 Database file path: ${file.path}');
    }

    return NativeDatabase(file);
  });
}
