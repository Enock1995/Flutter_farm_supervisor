// lib/providers/pest_disease_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/pest_disease_service.dart';

class PestDiseaseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<FarmAlert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  // Browse state
  String _selectedCrop = 'All Crops';
  String _searchQuery = '';
  String _typeFilter = 'All'; // 'All' | 'pest' | 'disease'

  List<FarmAlert> get alerts => _alerts;
  List<FarmAlert> get activeAlerts =>
      _alerts.where((a) => !a.isResolved).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCrop => _selectedCrop;
  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  int get activeAlertCount => activeAlerts.length;

  // ---------------------------------------------------------------------------
  // FILTERED DATABASE VIEW
  // ---------------------------------------------------------------------------

  List<PestOrDisease> get filteredPests {
    List<PestOrDisease> list;

    if (_searchQuery.isNotEmpty) {
      list = PestDiseaseService.search(_searchQuery);
    } else {
      list = PestDiseaseService.getByCrop(_selectedCrop);
    }

    if (_typeFilter != 'All') {
      list = list.where((p) => p.type == _typeFilter).toList();
    }

    return list;
  }

  void setSelectedCrop(String crop) {
    _selectedCrop = crop;
    _searchQuery = '';
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String filter) {
    _typeFilter = filter;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCrop = 'All Crops';
    _searchQuery = '';
    _typeFilter = 'All';
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // LOAD ALERTS FROM DB
  // ---------------------------------------------------------------------------

  Future<void> loadAlerts(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS farm_alerts (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          pest_disease_id TEXT NOT NULL,
          pest_disease_name TEXT NOT NULL,
          affected_crop TEXT NOT NULL,
          plot_or_field TEXT,
          severity TEXT NOT NULL DEFAULT 'medium',
          notes TEXT,
          reported_at TEXT NOT NULL,
          is_resolved INTEGER NOT NULL DEFAULT 0,
          resolved_at TEXT
        )
      ''');

      final maps = await db.query(
        'farm_alerts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'reported_at DESC',
      );
      _alerts = maps.map(FarmAlert.fromMap).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ADD ALERT
  // ---------------------------------------------------------------------------

  Future<void> addAlert({
    required String userId,
    required PestOrDisease pestDisease,
    required String affectedCrop,
    String? plotOrField,
    required String severity,
    String notes = '',
  }) async {
    final id = 'alert_${DateTime.now().millisecondsSinceEpoch}';
    final alert = FarmAlert(
      id: id,
      userId: userId,
      pestDiseaseId: pestDisease.id,
      pestDiseaseName: pestDisease.name,
      affectedCrop: affectedCrop,
      plotOrField: plotOrField,
      severity: severity,
      notes: notes,
      reportedAt: DateTime.now(),
    );

    try {
      final db = await _db.database;
      await db.insert('farm_alerts', alert.toMap());
      _alerts.insert(0, alert);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // RESOLVE ALERT
  // ---------------------------------------------------------------------------

  Future<void> resolveAlert(String alertId) async {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx == -1) return;

    final updated =
        _alerts[idx].copyWith(isResolved: true);
    _alerts[idx] = updated;
    notifyListeners();

    try {
      final db = await _db.database;
      await db.update(
        'farm_alerts',
        {
          'is_resolved': 1,
          'resolved_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [alertId],
      );
    } catch (e) {
      _error = e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE ALERT
  // ---------------------------------------------------------------------------

  Future<void> deleteAlert(String alertId) async {
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
    try {
      final db = await _db.database;
      await db.delete('farm_alerts',
          where: 'id = ?', whereArgs: [alertId]);
    } catch (e) {
      _error = e.toString();
    }
  }
}