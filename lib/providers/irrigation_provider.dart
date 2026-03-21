// lib/providers/irrigation_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/irrigation_service.dart';
import '../services/ai_service.dart';
import '../services/weather_service.dart';

class SmartIrrigationAlert {
  final String plotName;
  final String type; // 'overdue' | 'heat_stress' | 'rain_skip' | 'low_water'
  final String title;
  final String message;
  final String icon;
  final String level; // 'warning' | 'danger' | 'info'

  const SmartIrrigationAlert({
    required this.plotName,
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.level,
  });
}

class IrrigationProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<IrrigationSetup> _setups = [];
  List<IrrigationLog> _logs = [];
  bool _isLoading = false;
  String? _error;

  // ── AI Schedule ──────────────────────────────────────────
  IrrigationAiSchedule? _aiSchedule;
  bool _aiLoading = false;
  String? _aiError;

  IrrigationAiSchedule? get aiSchedule => _aiSchedule;
  bool get aiLoading => _aiLoading;
  String? get aiError => _aiError;

  List<IrrigationSetup> get setups => _setups;
  List<IrrigationSetup> get activeSetups =>
      _setups.where((s) => s.isActive).toList();
  List<IrrigationLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeCount => activeSetups.length;

  double get totalAreaHa =>
      activeSetups.fold(0.0, (sum, s) => sum + s.areaHa);

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

  int? daysSinceIrrigation(String setupId) {
    final log = lastLogForSetup(setupId);
    if (log == null) return null;
    return DateTime.now().difference(log.irrigatedAt).inDays;
  }

  double get weeklyWaterApplied {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _logs
        .where((l) => l.irrigatedAt.isAfter(weekAgo))
        .fold(0.0, (sum, l) => sum + l.waterAppliedLitres);
  }

  // ── Smart Alerts (rule-based, no API) ───────────────────
  /// Generates smart alerts by checking all active plots against
  /// current weather conditions. No AI call — instant, offline-capable.
  List<SmartIrrigationAlert> getSmartAlerts({
    WeatherData? weather,
  }) {
    final alerts = <SmartIrrigationAlert>[];

    for (final setup in activeSetups) {
      final days = daysSinceIrrigation(setup.id);

      // Overdue check
      if (days != null && days >= 5) {
        alerts.add(SmartIrrigationAlert(
          plotName: setup.plotName,
          type: 'overdue',
          title: '${setup.plotName} — Overdue',
          message:
              'Last irrigated $days days ago. '
              '${setup.currentCrop != null ? '${setup.currentCrop} requires regular watering.' : 'Check if plot needs water.'}',
          icon: '🔴',
          level: days >= 7 ? 'danger' : 'warning',
        ));
      }

      // Heat stress check
      if (weather != null && weather.tempC > 33 && days != null && days >= 2) {
        alerts.add(SmartIrrigationAlert(
          plotName: setup.plotName,
          type: 'heat_stress',
          title: '${setup.plotName} — Heat Stress Risk',
          message:
              'Current temperature ${weather.tempC.round()}°C. '
              'Irrigate ${setup.plotName} today to prevent heat stress. '
              'Apply in early morning or late evening.',
          icon: '🌡️',
          level: 'warning',
        ));
      }

      // Rain skip suggestion
      if (weather != null &&
          (weather.rainMm1h ?? 0) > 8 &&
          (days == null || days <= 1)) {
        alerts.add(SmartIrrigationAlert(
          plotName: setup.plotName,
          type: 'rain_skip',
          title: '${setup.plotName} — Skip Today',
          message:
              '${weather.rainMm1h!.toStringAsFixed(1)} mm of rain recorded. '
              'Skip irrigation for ${setup.plotName} today — natural rainfall is sufficient.',
          icon: '🌧️',
          level: 'info',
        ));
      }

      // No crop assigned warning
      if (setup.currentCrop == null) {
        alerts.add(SmartIrrigationAlert(
          plotName: setup.plotName,
          type: 'low_water',
          title: '${setup.plotName} — No Crop Set',
          message:
              'Assign a crop to ${setup.plotName} to get accurate irrigation scheduling.',
          icon: '🌱',
          level: 'info',
        ));
      }
    }

    return alerts;
  }

  // ── AI Schedule ──────────────────────────────────────────
  /// Calls Claude AI to generate an optimised irrigation plan
  /// based on all active plots + current weather data.
  Future<void> loadAiSchedule({
    required WeatherData weather,
    required List<ForecastDay> forecast,
    required String district,
  }) async {
    if (activeSetups.isEmpty) return;

    _aiLoading = true;
    _aiError = null;
    notifyListeners();

    try {
      final eto = IrrigationService.estimateEto(DateTime.now());

      final plots = activeSetups.map((s) {
        final last = lastLogForSetup(s.id);
        return {
          'name': s.plotName,
          'area': s.areaHa.toStringAsFixed(2),
          'crop': s.currentCrop,
          'stage': s.growthStage,
          'system': s.systemType,
          'last_irrigated': last != null
              ? '${daysSinceIrrigation(s.id)} days ago'
              : 'never',
        };
      }).toList();

      final forecastSummary = forecast
          .map((d) => {
                'day': d.dayName,
                'condition': d.condition,
                'max': d.tempMaxC.round(),
                'rain': d.rainChance,
              })
          .toList();

      _aiSchedule = await AiService.irrigationAiSchedule(
        plots: plots,
        currentTempC: weather.tempC,
        humidity: weather.humidity.toDouble(),
        rainMmToday: weather.rainMm1h ?? 0.0,
        etoMmDay: eto,
        condition: weather.condition,
        forecastSummary: forecastSummary,
        district: district,
      );
    } catch (e) {
      _aiError = e.toString().replaceAll('AiException: ', '');
    }

    _aiLoading = false;
    notifyListeners();
  }

  void clearAiSchedule() {
    _aiSchedule = null;
    _aiError = null;
    notifyListeners();
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
      _setups = setupMaps.map(IrrigationSetup.fromMap).toList();

      final logMaps = await db.query(
        'irrigation_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'irrigated_at DESC',
        limit: 100,
      );
      _logs = logMaps.map(IrrigationLog.fromMap).toList();

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
      final id = 'irr_${DateTime.now().millisecondsSinceEpoch}';
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
    final idx = _setups.indexWhere((s) => s.id == setupId);
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
    final waterAppliedLitres = (durationMinutes / 60) * flowRateLph;
    final areaM2 = areaHa * 10000;
    final waterMm = waterAppliedLitres / areaM2;

    try {
      final db = await _db.database;
      final id = 'log_${DateTime.now().millisecondsSinceEpoch}';
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