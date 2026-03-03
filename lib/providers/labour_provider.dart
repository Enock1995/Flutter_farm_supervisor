// lib/providers/labour_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/labour_service.dart';

class LabourProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<FarmWorker> _workers = [];
  List<AttendanceRecord> _attendance = [];
  bool _isLoading = false;
  String? _error;

  List<FarmWorker> get workers => _workers;
  List<FarmWorker> get activeWorkers =>
      _workers.where((w) => w.isActive).toList();
  List<AttendanceRecord> get attendance => _attendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activeCount => activeWorkers.length;

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  Future<void> load(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;

      // Create tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS farm_workers (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          full_name TEXT NOT NULL,
          phone TEXT,
          worker_type TEXT NOT NULL DEFAULT 'casual',
          daily_rate_usd REAL NOT NULL,
          assigned_plot TEXT,
          national_id TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          added_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS worker_attendance (
          id TEXT PRIMARY KEY,
          worker_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'absent',
          notes TEXT,
          hours_worked REAL NOT NULL DEFAULT 8,
          UNIQUE(worker_id, date)
        )
      ''');

      // Load workers
      final workerMaps = await db.query(
        'farm_workers',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'full_name ASC',
      );
      _workers = workerMaps.map(FarmWorker.fromMap).toList();

      // Load attendance (last 60 days)
      final cutoff = DateTime.now()
          .subtract(const Duration(days: 60))
          .toIso8601String();
      final attMaps = await db.query(
        'worker_attendance',
        where: 'user_id = ? AND date >= ?',
        whereArgs: [userId, cutoff],
        orderBy: 'date DESC',
      );
      _attendance =
          attMaps.map(AttendanceRecord.fromMap).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE HELPERS
  // ---------------------------------------------------------------------------

  AttendanceRecord? getAttendance(
      String workerId, DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return _attendance.firstWhere(
        (a) =>
            a.workerId == workerId &&
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  // Today's attendance map: workerId -> status
  Map<String, String> get todayAttendance {
    final today = DateTime.now();
    final map = <String, String>{};
    for (final w in activeWorkers) {
      final rec = getAttendance(w.id, today);
      map[w.id] = rec?.status ?? 'not_marked';
    }
    return map;
  }

  int get todayMarkedCount {
    final today = DateTime.now();
    return _attendance
        .where((a) =>
            a.date.year == today.year &&
            a.date.month == today.month &&
            a.date.day == today.day)
        .length;
  }

  // ---------------------------------------------------------------------------
  // PAY SUMMARIES
  // ---------------------------------------------------------------------------

  List<WorkerPaySummary> getSummaries({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return activeWorkers.map((w) {
      final workerAtt = _attendance
          .where((a) => a.workerId == w.id)
          .toList();
      return LabourService.calculatePay(
        worker: w,
        attendance: workerAtt,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    }).toList();
  }

  double totalWagesDue({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) =>
      getSummaries(
              periodStart: periodStart,
              periodEnd: periodEnd)
          .fold(0.0, (sum, s) => sum + s.totalPayUsd);

  // ---------------------------------------------------------------------------
  // CRUD — WORKERS
  // ---------------------------------------------------------------------------

  Future<FarmWorker?> addWorker({
    required String userId,
    required String fullName,
    String? phone,
    String workerType = 'casual',
    required double dailyRateUsd,
    String? assignedPlot,
    String? nationalId,
  }) async {
    try {
      final db = await _db.database;
      final id =
          'worker_${DateTime.now().millisecondsSinceEpoch}';
      final worker = FarmWorker(
        id: id,
        userId: userId,
        fullName: fullName,
        phone: phone,
        workerType: workerType,
        dailyRateUsd: dailyRateUsd,
        assignedPlot: assignedPlot,
        nationalId: nationalId,
        addedAt: DateTime.now(),
      );
      await db.insert('farm_workers', worker.toMap());
      _workers.add(worker);
      _workers.sort(
          (a, b) => a.fullName.compareTo(b.fullName));
      notifyListeners();
      return worker;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deactivateWorker(String workerId) async {
    final idx =
        _workers.indexWhere((w) => w.id == workerId);
    if (idx == -1) return;
    final updated =
        _workers[idx].copyWith(isActive: false);
    _workers[idx] = updated;
    notifyListeners();
    try {
      final db = await _db.database;
      await db.update(
        'farm_workers',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [workerId],
      );
    } catch (e) {
      _error = e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD — ATTENDANCE
  // ---------------------------------------------------------------------------

  Future<void> markAttendance({
    required String userId,
    required String workerId,
    required DateTime date,
    required String status,
    String? notes,
  }) async {
    final id =
        'att_${workerId}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final hours = status == 'half' ? 4.0 : 8.0;
    final record = AttendanceRecord(
      id: id,
      workerId: workerId,
      userId: userId,
      date: DateTime(date.year, date.month, date.day),
      status: status,
      notes: notes,
      hoursWorked: hours,
    );

    // Update in memory
    _attendance.removeWhere((a) =>
        a.workerId == workerId &&
        a.date.year == date.year &&
        a.date.month == date.month &&
        a.date.day == date.day);
    _attendance.add(record);
    notifyListeners();

    // Persist
    try {
      final db = await _db.database;
      await db.execute('''
        INSERT OR REPLACE INTO worker_attendance
        (id, worker_id, user_id, date, status, notes, hours_worked)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        id,
        workerId,
        userId,
        record.date.toIso8601String(),
        status,
        notes,
        hours,
      ]);
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Mark all active workers at once (bulk attendance)
  Future<void> markBulkAttendance({
    required String userId,
    required DateTime date,
    required Map<String, String> statusMap,
  }) async {
    for (final entry in statusMap.entries) {
      await markAttendance(
        userId: userId,
        workerId: entry.key,
        date: date,
        status: entry.value,
      );
    }
  }
}