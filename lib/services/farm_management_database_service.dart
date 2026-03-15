// lib/services/farm_management_database_service.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'task_activity_database_service.dart';
import '../models/farm_management_model.dart';

class FarmManagementDatabaseService {
  static Future<Database> get _db async => DatabaseService().database;

  // =========================================================
  // TABLE CREATION — called from database_service onCreate/onUpgrade
  // =========================================================
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farms (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        farm_code TEXT UNIQUE NOT NULL,
        farm_name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        size_hectares REAL NOT NULL,
        geofence_radius_meters REAL NOT NULL DEFAULT 500,
        crop_types TEXT NOT NULL DEFAULT '',
        livestock_types TEXT NOT NULL DEFAULT '',
        district TEXT NOT NULL,
        province TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workers (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        farm_code TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        pin TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'fieldWorker',
        status TEXT NOT NULL DEFAULT 'pending',
        joined_at TEXT NOT NULL,
        approved_at TEXT,
        FOREIGN KEY (farm_id) REFERENCES farms (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clock_records (
        id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        farm_id TEXT NOT NULL,
        worker_name TEXT NOT NULL,
        clock_in_lat REAL NOT NULL,
        clock_in_lng REAL NOT NULL,
        within_geofence INTEGER NOT NULL DEFAULT 1,
        clock_in_time TEXT NOT NULL,
        clock_out_lat REAL,
        clock_out_lng REAL,
        clock_out_time TEXT,
        hours_worked REAL,
        status TEXT NOT NULL DEFAULT 'clockedIn',
        FOREIGN KEY (worker_id) REFERENCES workers (id),
        FOREIGN KEY (farm_id) REFERENCES farms (id)
      )
    ''');

    // Tasks + Activity Feed tables
    await TaskActivityDatabaseService.createTables(db);
  }

  // =========================================================
  // FARMS
  // =========================================================

  static String generateFarmCode() {
    final random = Random.secure();
    final number = 1000 + random.nextInt(9000);
    return 'FARM-$number';
  }

  static Future<FarmEntity> saveFarm(FarmEntity farm) async {
    final db = await _db;
    String code = farm.farmCode;
    while (true) {
      final existing = await db.query('farms',
          where: 'farm_code = ?', whereArgs: [code], limit: 1);
      if (existing.isEmpty) break;
      code = generateFarmCode();
    }

    final toSave = FarmEntity(
      id: farm.id,
      ownerId: farm.ownerId,
      farmCode: code,
      farmName: farm.farmName,
      latitude: farm.latitude,
      longitude: farm.longitude,
      sizeHectares: farm.sizeHectares,
      geofenceRadiusMeters: farm.geofenceRadiusMeters,
      cropTypes: farm.cropTypes,
      livestockTypes: farm.livestockTypes,
      district: farm.district,
      province: farm.province,
      createdAt: farm.createdAt,
      updatedAt: farm.updatedAt,
    );

    await db.insert('farms', toSave.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return toSave;
  }

  static Future<List<FarmEntity>> getFarmsByOwner(String ownerId) async {
    final db = await _db;
    final rows = await db.query('farms',
        where: 'owner_id = ?',
        whereArgs: [ownerId],
        orderBy: 'created_at DESC');
    return rows.map(FarmEntity.fromMap).toList();
  }

  static Future<FarmEntity?> getFarmByCode(String farmCode) async {
    final db = await _db;
    final rows = await db.query('farms',
        where: 'farm_code = ?', whereArgs: [farmCode], limit: 1);
    return rows.isEmpty ? null : FarmEntity.fromMap(rows.first);
  }

  static Future<FarmEntity?> getFarmById(String id) async {
    final db = await _db;
    final rows =
        await db.query('farms', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : FarmEntity.fromMap(rows.first);
  }

  static Future<void> updateGeofence(
      String farmId, double radiusMeters) async {
    final db = await _db;
    await db.update(
      'farms',
      {
        'geofence_radius_meters': radiusMeters,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [farmId],
    );
  }

  // =========================================================
  // WORKERS
  // =========================================================

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  static Future<WorkerModel> registerWorker(WorkerModel worker) async {
    final db = await _db;
    await db.insert('workers', worker.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return worker;
  }

  static Future<List<WorkerModel>> getWorkersByFarm(String farmId) async {
    final db = await _db;
    final rows = await db.query('workers',
        where: 'farm_id = ?',
        whereArgs: [farmId],
        orderBy: 'joined_at DESC');
    return rows.map(WorkerModel.fromMap).toList();
  }

  static Future<List<WorkerModel>> getPendingWorkers(String ownerId) async {
    final db = await _db;
    final rows = await db.query('workers',
        where: 'owner_id = ? AND status = ?',
        whereArgs: [ownerId, 'pending'],
        orderBy: 'joined_at DESC');
    return rows.map(WorkerModel.fromMap).toList();
  }

  static Future<void> updateWorkerStatus(
      String workerId, WorkerStatus status) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'workers',
      {
        'status': status.name,
        if (status == WorkerStatus.approved) 'approved_at': now,
      },
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  static Future<WorkerModel?> getWorkerByPhoneAndFarm(
      String phone, String farmCode) async {
    final db = await _db;
    final rows = await db.query('workers',
        where: 'phone = ? AND farm_code = ?',
        whereArgs: [phone, farmCode],
        limit: 1);
    return rows.isEmpty ? null : WorkerModel.fromMap(rows.first);
  }

  static Future<bool> isPhoneRegisteredOnFarm(
      String phone, String farmCode) async {
    final db = await _db;
    final rows = await db.query('workers',
        columns: ['id'],
        where: 'phone = ? AND farm_code = ?',
        whereArgs: [phone, farmCode],
        limit: 1);
    return rows.isNotEmpty;
  }

  // =========================================================
  // CLOCK RECORDS
  // =========================================================

  static Future<void> clockIn(ClockRecord record) async {
    final db = await _db;
    await db.insert('clock_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> clockOut({
    required String recordId,
    required double lat,
    required double lng,
  }) async {
    final db = await _db;
    final now = DateTime.now();

    final rows = await db.query('clock_records',
        where: 'id = ?', whereArgs: [recordId], limit: 1);
    if (rows.isEmpty) return;

    final record = ClockRecord.fromMap(rows.first);
    final hours = now.difference(record.clockInTime).inMinutes / 60.0;

    await db.update(
      'clock_records',
      {
        'clock_out_lat': lat,
        'clock_out_lng': lng,
        'clock_out_time': now.toIso8601String(),
        'hours_worked': double.parse(hours.toStringAsFixed(2)),
        'status': ClockStatus.clockedOut.name,
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  static Future<ClockRecord?> getActiveClockRecord(String workerId) async {
    final db = await _db;
    final rows = await db.query('clock_records',
        where: 'worker_id = ? AND status = ?',
        whereArgs: [workerId, ClockStatus.clockedIn.name],
        orderBy: 'clock_in_time DESC',
        limit: 1);
    return rows.isEmpty ? null : ClockRecord.fromMap(rows.first);
  }

  static Future<List<ClockRecord>> getClockHistory(String workerId,
      {int limit = 30}) async {
    final db = await _db;
    final rows = await db.query('clock_records',
        where: 'worker_id = ?',
        whereArgs: [workerId],
        orderBy: 'clock_in_time DESC',
        limit: limit);
    return rows.map(ClockRecord.fromMap).toList();
  }

  static Future<List<ClockRecord>> getLiveFarmAttendance(
      String farmId) async {
    final db = await _db;
    final rows = await db.query('clock_records',
        where: 'farm_id = ? AND status = ?',
        whereArgs: [farmId, ClockStatus.clockedIn.name],
        orderBy: 'clock_in_time ASC');
    return rows.map(ClockRecord.fromMap).toList();
  }

  static Future<List<ClockRecord>> getFarmClockHistory(String farmId,
      {int limit = 100}) async {
    final db = await _db;
    final rows = await db.query('clock_records',
        where: 'farm_id = ?',
        whereArgs: [farmId],
        orderBy: 'clock_in_time DESC',
        limit: limit);
    return rows.map(ClockRecord.fromMap).toList();
  }
}