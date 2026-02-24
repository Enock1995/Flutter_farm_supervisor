// lib/providers/horticulture_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class HortiPlot {
  final String id;
  final String userId;
  final String cropName;
  final double plotSizeM2;
  final DateTime? plantingDate;
  final DateTime? expectedHarvestDate;
  final DateTime? actualHarvestDate;
  final String irrigationMethod;
  final String targetMarket;
  final double? yieldKg;
  final double? revenueUsd;
  final String? notes;
  final DateTime createdAt;

  const HortiPlot({
    required this.id,
    required this.userId,
    required this.cropName,
    required this.plotSizeM2,
    this.plantingDate,
    this.expectedHarvestDate,
    this.actualHarvestDate,
    required this.irrigationMethod,
    required this.targetMarket,
    this.yieldKg,
    this.revenueUsd,
    this.notes,
    required this.createdAt,
  });

  bool get isActive => actualHarvestDate == null;

  int get daysGrowing => plantingDate != null
      ? DateTime.now().difference(plantingDate!).inDays
      : 0;

  double get plotSizeHa => plotSizeM2 / 10000;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'crop_name': cropName,
        'plot_size_m2': plotSizeM2,
        'planting_date': plantingDate?.toIso8601String(),
        'expected_harvest_date':
            expectedHarvestDate?.toIso8601String(),
        'actual_harvest_date':
            actualHarvestDate?.toIso8601String(),
        'irrigation_method': irrigationMethod,
        'target_market': targetMarket,
        'yield_kg': yieldKg,
        'revenue_usd': revenueUsd,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory HortiPlot.fromMap(Map<String, dynamic> m) =>
      HortiPlot(
        id: m['id'],
        userId: m['user_id'],
        cropName: m['crop_name'],
        plotSizeM2: (m['plot_size_m2'] as num).toDouble(),
        plantingDate: m['planting_date'] != null
            ? DateTime.parse(m['planting_date'])
            : null,
        expectedHarvestDate:
            m['expected_harvest_date'] != null
                ? DateTime.parse(m['expected_harvest_date'])
                : null,
        actualHarvestDate: m['actual_harvest_date'] != null
            ? DateTime.parse(m['actual_harvest_date'])
            : null,
        irrigationMethod: m['irrigation_method'] ?? 'Drip',
        targetMarket: m['target_market'] ?? 'Local market',
        yieldKg: m['yield_kg'] != null
            ? (m['yield_kg'] as num).toDouble()
            : null,
        revenueUsd: m['revenue_usd'] != null
            ? (m['revenue_usd'] as num).toDouble()
            : null,
        notes: m['notes'],
        createdAt: DateTime.parse(m['created_at']),
      );
}

class HorticultureProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<HortiPlot> _plots = [];
  bool _isLoading = false;
  String? _error;

  List<HortiPlot> get plots => _plots;
  List<HortiPlot> get activePlots =>
      _plots.where((p) => p.isActive).toList();
  List<HortiPlot> get completedPlots =>
      _plots.where((p) => !p.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlots(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS horti_plots (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          crop_name TEXT NOT NULL,
          plot_size_m2 REAL NOT NULL,
          planting_date TEXT,
          expected_harvest_date TEXT,
          actual_harvest_date TEXT,
          irrigation_method TEXT NOT NULL DEFAULT 'Drip',
          target_market TEXT NOT NULL DEFAULT 'Local market',
          yield_kg REAL,
          revenue_usd REAL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      final maps = await db.query(
        'horti_plots',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      _plots = maps.map(HortiPlot.fromMap).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<HortiPlot?> addPlot({
    required String userId,
    required String cropName,
    required double plotSizeM2,
    DateTime? plantingDate,
    DateTime? expectedHarvestDate,
    required String irrigationMethod,
    required String targetMarket,
    String? notes,
  }) async {
    try {
      final db = await _db.database;
      final id =
          DateTime.now().millisecondsSinceEpoch.toString();
      final plot = HortiPlot(
        id: id,
        userId: userId,
        cropName: cropName,
        plotSizeM2: plotSizeM2,
        plantingDate: plantingDate,
        expectedHarvestDate: expectedHarvestDate,
        irrigationMethod: irrigationMethod,
        targetMarket: targetMarket,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await db.insert('horti_plots', plot.toMap());
      _plots.insert(0, plot);
      notifyListeners();
      return plot;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> recordHarvest({
    required String plotId,
    required DateTime harvestDate,
    required double yieldKg,
    required double revenueUsd,
  }) async {
    try {
      final db = await _db.database;
      await db.update(
        'horti_plots',
        {
          'actual_harvest_date':
              harvestDate.toIso8601String(),
          'yield_kg': yieldKg,
          'revenue_usd': revenueUsd,
        },
        where: 'id = ?',
        whereArgs: [plotId],
      );
      final idx =
          _plots.indexWhere((p) => p.id == plotId);
      if (idx != -1) {
        final old = _plots[idx];
        _plots[idx] = HortiPlot(
          id: old.id,
          userId: old.userId,
          cropName: old.cropName,
          plotSizeM2: old.plotSizeM2,
          plantingDate: old.plantingDate,
          expectedHarvestDate: old.expectedHarvestDate,
          actualHarvestDate: harvestDate,
          irrigationMethod: old.irrigationMethod,
          targetMarket: old.targetMarket,
          yieldKg: yieldKg,
          revenueUsd: revenueUsd,
          notes: old.notes,
          createdAt: old.createdAt,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePlot(String plotId) async {
    try {
      final db = await _db.database;
      await db.delete('horti_plots',
          where: 'id = ?', whereArgs: [plotId]);
      _plots.removeWhere((p) => p.id == plotId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}