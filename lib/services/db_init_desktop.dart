// lib/services/db_init_desktop.dart
// Used on Windows and Linux only — initialises sqflite FFI.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initDatabaseFactory() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}