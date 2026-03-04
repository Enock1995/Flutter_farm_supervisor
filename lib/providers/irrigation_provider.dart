// lib/providers/irrigation_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/irrigation_service.dart';

class IrrigationProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<IrrigationSetup> _setups = [];
  List<IrrigationLog> _logs = [];
  bool _isLoading = false;
  String? _error;

  List<IrrigationSetup> get setups => _setups;
  List<IrrigationSetup> get activeSetups =>
      _setups.where((s) => s.isActive).toList();
  List<IrrigationLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeCount => activeSetups.length;

  double get totalAreaHa => activeSetups.fold(
      0.0, (sum, s) => sum + s.areaHa);

  // Last irrigation per setup
  IrrigationLog? lastLogForSetup(String setupId) {
    try {
      return _logs
          .where((l) => l.setupId == setupId)
          .reduce((a, b) =>
              a.irrigatedAt.isAfter(b.irrigatedAt) ? a : b);
    } catch (_) {
      return null;
    }
  }

  // Days since last irrigation for a setup
  int? daysSinceIrrigation(String setupId) {
    final log = lastLogForSetup(setupId);
    if (log == null) return null;
    return DateTime.now()
        .difference(log.irrigatedAt)
        .inDays;
  }

  // This week's total water applied (litres)
  double get weeklyWaterApplied {
    final weekAgo = DateTime.now()
        .subtract(const Duration(days: 7));
    return _logs
        .where((l) => l.irrigatedAt.isAfter(weekAgo))
        .fold(0.0,
            (sum, l) => sum + l.waterAppliedLitres);
  }

  // ---------------------------------------------------------------------------
  // LOAD
  // ---------------------------------------------------------------------------

  Future<void> load(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;

      await db.execute('''
        CREATE TABLE IF NOT EXISTS irrigation_setups (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          plot_name TEXT NOT NULL,
          area_ha REAL NOT NULL,
          system_type TEXT NOT NULL DEFAULT 'drip',
          flow_rate_lph REAL,
          water_source TEXT,
          current_crop TEXT,
          growth_stage TEXT,
          planting_date TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS irrigation_logs (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          setup_id TEXT NOT NULL,
          plot_name TEXT NOT NULL,
          irrigated_at TEXT NOT NULL,
          duration_minutes REAL NOT NULL,
          water_applied_litres REAL NOT NULL,
          water_applied_mm REAL NOT NULL,
          notes TEXT,
          weather_condition TEXT
        )
      ''');

      final setupMaps = await db.query(
        'irrigation_setups',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      _setups =
          setupMaps.map(IrrigationSetup.fromMap).toList();

      final logMaps = await db.query(
        'irrigation_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'irrigated_at DESC',
        limit: 100,
      );
      _logs =
          logMaps.map(IrrigationLog.fromMap).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CRUD — SETUPS
  // ---------------------------------------------------------------------------

  Future<IrrigationSetup?> addSetup({
    required String userId,
    required String plotName,
    required double areaHa,
    required String systemType,
    double? flowRateLph,
    String? waterSource,
    String? currentCrop,
    String? growthStage,
    DateTime? plantingDate,
  }) async {
    try {
      final db = await _db.database;
      final id =
          'irr_${DateTime.now().millisecondsSinceEpoch}';
      final setup = IrrigationSetup(
        id: id,
        userId: userId,
        plotName: plotName,
        areaHa: areaHa,
        systemType: systemType,
        flowRateLph: flowRateLph,
        waterSource: waterSource,
        currentCrop: currentCrop,
        growthStage: growthStage,
        plantingDate: plantingDate,
        createdAt: DateTime.now(),
      );
      await db.insert('irrigation_setups', setup.toMap());
      _setups.insert(0, setup);
      notifyListeners();
      return setup;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateSetupCrop({
    required String setupId,
    required String crop,
    required String stage,
  }) async {
    final idx =
        _setups.indexWhere((s) => s.id == setupId);
    if (idx == -1) return;
    _setups[idx] = _setups[idx].copyWith(
      currentCrop: crop,
      growthStage: stage,
    );
    notifyListeners();
    try {
      final db = await _db.database;
      await db.update(
        'irrigation_setups',
        {'current_crop': crop, 'growth_stage': stage},
        where: 'id = ?',
        whereArgs: [setupId],
      );
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> deleteSetup(String setupId) async {
    _setups.removeWhere((s) => s.id == setupId);
    _logs.removeWhere((l) => l.setupId == setupId);
    notifyListeners();
    try {
      final db = await _db.database;
      await db.delete('irrigation_setups',
          where: 'id = ?', whereArgs: [setupId]);
      await db.delete('irrigation_logs',
          where: 'setup_id = ?', whereArgs: [setupId]);
    } catch (e) {
      _error = e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD — LOGS
  // ---------------------------------------------------------------------------

  Future<IrrigationLog?> logIrrigation({
    required String userId,
    required String setupId,
    required String plotName,
    required double areaHa,
    required DateTime irrigatedAt,
    required double durationMinutes,
    required double flowRateLph,
    String? notes,
    String? weatherCondition,
  }) async {
    final waterAppliedLitres =
        (durationMinutes / 60) * flowRateLph;
    final areaM2 = areaHa * 10000;
    final waterMm = waterAppliedLitres / areaM2;

    try {
      final db = await _db.database;
      final id =
          'log_${DateTime.now().millisecondsSinceEpoch}';
      final log = IrrigationLog(
        id: id,
        userId: userId,
        setupId: setupId,
        plotName: plotName,
        irrigatedAt: irrigatedAt,
        durationMinutes: durationMinutes,
        waterAppliedLitres: waterAppliedLitres,
        waterAppliedMm: waterMm,
        notes: notes,
        weatherCondition: weatherCondition,
      );
      await db.insert('irrigation_logs', log.toMap());
      _logs.insert(0, log);
      notifyListeners();
      return log;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteLog(String logId) async {
    _logs.removeWhere((l) => l.id == logId);
    notifyListeners();
    try {
      final db = await _db.database;
      await db.delete('irrigation_logs',
          where: 'id = ?', whereArgs: [logId]);
    } catch (e) {
      _error = e.toString();
    }
  }
}