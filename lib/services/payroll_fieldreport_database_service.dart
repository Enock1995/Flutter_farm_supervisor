// lib/services/payroll_fieldreport_database_service.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/payroll_fieldreport_model.dart';

class PayrollFieldReportDatabaseService {
  static Future<Database> get _db async => DatabaseService().database;

  // =========================================================
  // TABLE CREATION — called from database_service v6 migration
  // =========================================================
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payroll_records (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        worker_id TEXT NOT NULL,
        worker_name TEXT NOT NULL,
        worker_phone TEXT NOT NULL,
        hours_worked REAL NOT NULL,
        hourly_rate_usd REAL NOT NULL,
        total_amount_usd REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        paynow_poll_url TEXT,
        paynow_reference TEXT,
        failure_reason TEXT,
        period_start TEXT NOT NULL,
        period_end TEXT NOT NULL,
        created_at TEXT NOT NULL,
        paid_at TEXT,
        FOREIGN KEY (farm_id) REFERENCES farms (id),
        FOREIGN KEY (worker_id) REFERENCES workers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS field_reports (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        reported_by_worker_id TEXT NOT NULL,
        reported_by_name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'generalUpdate',
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        field_or_plot TEXT,
        requires_owner_attention INTEGER NOT NULL DEFAULT 0,
        owner_viewed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        viewed_at TEXT,
        FOREIGN KEY (farm_id) REFERENCES farms (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS photo_entries (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        taken_by_worker_id TEXT NOT NULL,
        taken_by_name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general',
        caption TEXT NOT NULL DEFAULT '',
        field_or_plot TEXT,
        image_path TEXT NOT NULL,
        taken_at TEXT NOT NULL,
        FOREIGN KEY (farm_id) REFERENCES farms (id)
      )
    ''');
  }

  // =========================================================
  // PAYROLL
  // =========================================================

  static Future<PayrollRecord> insertPayroll(
      PayrollRecord record) async {
    final db = await _db;
    await db.insert('payroll_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return record;
  }

  static Future<void> updatePayrollStatus(
    String id,
    PayrollStatus status, {
    String? paynowPollUrl,
    String? paynowReference,
    String? failureReason,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'payroll_records',
      {
        'status': status.name,
        if (paynowPollUrl != null) 'paynow_poll_url': paynowPollUrl,
        if (paynowReference != null)
          'paynow_reference': paynowReference,
        if (failureReason != null) 'failure_reason': failureReason,
        if (status == PayrollStatus.paid) 'paid_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<PayrollRecord>> getPayrollByFarm(
    String farmId, {
    PayrollStatus? filterStatus,
    int limit = 100,
  }) async {
    final db = await _db;
    String where = 'farm_id = ?';
    final args = <dynamic>[farmId];
    if (filterStatus != null) {
      where += ' AND status = ?';
      args.add(filterStatus.name);
    }
    final rows = await db.query(
      'payroll_records',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(PayrollRecord.fromMap).toList();
  }

  static Future<List<PayrollRecord>> getPayrollByWorker(
      String workerId) async {
    final db = await _db;
    final rows = await db.query(
      'payroll_records',
      where: 'worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(PayrollRecord.fromMap).toList();
  }

  /// Sum of hours worked by a worker between two dates (for payroll calc)
  static Future<double> getTotalHoursWorked({
    required String workerId,
    required String farmId,
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT SUM(hours_worked) as total
      FROM clock_records
      WHERE worker_id = ?
        AND farm_id = ?
        AND status = 'clockedOut'
        AND clock_in_time >= ?
        AND clock_in_time <= ?
    ''', [workerId, farmId, from.toIso8601String(), to.toIso8601String()]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // =========================================================
  // FIELD REPORTS
  // =========================================================

  static Future<FieldReport> insertFieldReport(
      FieldReport report) async {
    final db = await _db;
    await db.insert('field_reports', report.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return report;
  }

  static Future<List<FieldReport>> getFieldReportsByFarm(
    String farmId, {
    bool unreadOnly = false,
    int limit = 60,
  }) async {
    final db = await _db;
    String where = 'farm_id = ?';
    final args = <dynamic>[farmId];
    if (unreadOnly) {
      where += ' AND owner_viewed = 0';
    }
    final rows = await db.query(
      'field_reports',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(FieldReport.fromMap).toList();
  }

  static Future<List<FieldReport>> getFieldReportsByWorker(
      String workerId) async {
    final db = await _db;
    final rows = await db.query(
      'field_reports',
      where: 'reported_by_worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(FieldReport.fromMap).toList();
  }

  static Future<void> markReportViewed(String reportId) async {
    final db = await _db;
    await db.update(
      'field_reports',
      {
        'owner_viewed': 1,
        'viewed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  static Future<int> getUnreadReportCount(String farmId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM field_reports WHERE farm_id = ? AND owner_viewed = 0',
      [farmId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // =========================================================
  // PHOTO DIARY
  // =========================================================

  static Future<PhotoEntry> insertPhoto(PhotoEntry entry) async {
    final db = await _db;
    await db.insert('photo_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return entry;
  }

  static Future<List<PhotoEntry>> getPhotosByFarm(
    String farmId, {
    PhotoDiaryCategory? filterCategory,
    int limit = 100,
  }) async {
    final db = await _db;
    String where = 'farm_id = ?';
    final args = <dynamic>[farmId];
    if (filterCategory != null) {
      where += ' AND category = ?';
      args.add(filterCategory.name);
    }
    final rows = await db.query(
      'photo_entries',
      where: where,
      whereArgs: args,
      orderBy: 'taken_at DESC',
      limit: limit,
    );
    return rows.map(PhotoEntry.fromMap).toList();
  }

  static Future<List<PhotoEntry>> getPhotosByWorker(
      String workerId) async {
    final db = await _db;
    final rows = await db.query(
      'photo_entries',
      where: 'taken_by_worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'taken_at DESC',
    );
    return rows.map(PhotoEntry.fromMap).toList();
  }

  static Future<void> deletePhoto(String photoId) async {
    final db = await _db;
    await db.delete('photo_entries',
        where: 'id = ?', whereArgs: [photoId]);
  }
}