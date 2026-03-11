// lib/services/db_init_stub.dart
// Used on Android and iOS — standard sqflite, no FFI needed.

Future<void> initDatabaseFactory() async {
  // Nothing to do on mobile — sqflite works natively.
}