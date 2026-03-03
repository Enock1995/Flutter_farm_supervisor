// lib/providers/soil_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/soil_service.dart';

class SoilProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<SoilRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  List<SoilRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalPlots => _records.length;

  int get plotsNeedingLime =>
      _records.where((r) => r.needsLime).length;

  SoilRecord? get mostRecent =>
      _records.isEmpty ? null : _records.first;

  // ---------------------------------------------------------------------------
  // LOAD
  // ---------------------------------------------------------------------------

  Future<void> load(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS soil_records (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          plot_name TEXT NOT NULL,
          test_date TEXT NOT NULL,
          ph REAL,
          nitrogen REAL,
          phosphorus REAL,
          potassium REAL,
          organic_matter REAL,
          texture TEXT,
          plot_size_ha REAL,
          lab_name TEXT,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      final maps = await db.query(
        'soil_records',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'test_date DESC',
      );
      _records = maps.map(SoilRecord.fromMap).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ADD
  // ---------------------------------------------------------------------------

  Future<SoilRecord?> addRecord({
    required String userId,
    required String plotName,
    required DateTime testDate,
    double? ph,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? organicMatter,
    String? texture,
    double? plotSizeHa,
    String? labName,
    String? notes,
  }) async {
    try {
      final db = await _db.database;
      final id =
          'soil_${DateTime.now().millisecondsSinceEpoch}';
      final record = SoilRecord(
        id: id,
        userId: userId,
        plotName: plotName,
        testDate: testDate,
        ph: ph,
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        organicMatter: organicMatter,
        texture: texture,
        plotSizeHa: plotSizeHa,
        labName: labName,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await db.insert('soil_records', record.toMap());
      _records.insert(0, record);
      notifyListeners();
      return record;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
    try {
      final db = await _db.database;
      await db.delete('soil_records',
          where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      _error = e.toString();
    }
  }
}