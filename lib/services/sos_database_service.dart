// lib/services/sos_database_service.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:sqflite/sqflite.dart';
import '../models/sos_model.dart';
import 'database_service.dart';

class SosDatabaseService {
  static Future<Database> get _db async => DatabaseService().database;

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sos_alerts (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        farm_code TEXT NOT NULL,
        worker_id TEXT NOT NULL,
        worker_name TEXT NOT NULL,
        worker_phone TEXT NOT NULL,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        triggered_at TEXT NOT NULL,
        acknowledged_at TEXT,
        resolved_at TEXT,
        acknowledged_by_name TEXT,
        resolution_note TEXT
      )
    ''');
  }

  static Future<SosAlert> insertAlert(SosAlert alert) async {
    final db = await _db;
    await db.insert('sos_alerts', alert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return alert;
  }

  static Future<List<SosAlert>> getAlertsByFarm(
    String farmId, {
    SosStatus? filterStatus,
  }) async {
    final db = await _db;
    final where =
        filterStatus != null ? 'farm_id = ? AND status = ?' : 'farm_id = ?';
    final args =
        filterStatus != null ? [farmId, filterStatus.name] : [farmId];
    final rows = await db.query(
      'sos_alerts',
      where: where,
      whereArgs: args,
      orderBy: 'triggered_at DESC',
    );
    return rows.map(SosAlert.fromMap).toList();
  }

  static Future<List<SosAlert>> getActiveAlertsByFarm(String farmId) async {
    return getAlertsByFarm(farmId, filterStatus: SosStatus.active);
  }

  static Future<List<SosAlert>> getAlertsByWorker(String workerId) async {
    final db = await _db;
    final rows = await db.query(
      'sos_alerts',
      where: 'worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'triggered_at DESC',
      limit: 20,
    );
    return rows.map(SosAlert.fromMap).toList();
  }

  static Future<void> acknowledgeAlert({
    required String alertId,
    required String acknowledgedByName,
  }) async {
    final db = await _db;
    await db.update(
      'sos_alerts',
      {
        'status': SosStatus.acknowledged.name,
        'acknowledged_at': DateTime.now().toIso8601String(),
        'acknowledged_by_name': acknowledgedByName,
      },
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  static Future<void> resolveAlert({
    required String alertId,
    required String resolutionNote,
  }) async {
    final db = await _db;
    await db.update(
      'sos_alerts',
      {
        'status': SosStatus.resolved.name,
        'resolved_at': DateTime.now().toIso8601String(),
        'resolution_note': resolutionNote,
      },
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  static Future<int> getActiveAlertCount(String farmId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sos_alerts WHERE farm_id = ? AND status = ?',
      [farmId, SosStatus.active.name],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}