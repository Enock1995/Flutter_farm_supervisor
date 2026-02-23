// lib/providers/crop_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class CropRecord {
  final String id;
  final String userId;
  final String cropName;
  final double? fieldSizeHa;
  final DateTime? plantingDate;
  final DateTime? expectedHarvestDate;
  final DateTime? actualHarvestDate;
  final double? yieldKg;
  final String? notes;
  final DateTime createdAt;

  const CropRecord({
    required this.id,
    required this.userId,
    required this.cropName,
    this.fieldSizeHa,
    this.plantingDate,
    this.expectedHarvestDate,
    this.actualHarvestDate,
    this.yieldKg,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'crop_name': cropName,
        'field_size_ha': fieldSizeHa,
        'planting_date': plantingDate?.toIso8601String(),
        'expected_harvest_date':
            expectedHarvestDate?.toIso8601String(),
        'actual_harvest_date':
            actualHarvestDate?.toIso8601String(),
        'yield_kg': yieldKg,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory CropRecord.fromMap(Map<String, dynamic> map) =>
      CropRecord(
        id: map['id'],
        userId: map['user_id'],
        cropName: map['crop_name'],
        fieldSizeHa: map['field_size_ha'] != null
            ? (map['field_size_ha'] as num).toDouble()
            : null,
        plantingDate: map['planting_date'] != null
            ? DateTime.parse(map['planting_date'])
            : null,
        expectedHarvestDate:
            map['expected_harvest_date'] != null
                ? DateTime.parse(map['expected_harvest_date'])
                : null,
        actualHarvestDate: map['actual_harvest_date'] != null
            ? DateTime.parse(map['actual_harvest_date'])
            : null,
        yieldKg: map['yield_kg'] != null
            ? (map['yield_kg'] as num).toDouble()
            : null,
        notes: map['notes'],
        createdAt: DateTime.parse(map['created_at']),
      );

  bool get isActive => actualHarvestDate == null;

  int get daysGrowing => plantingDate != null
      ? DateTime.now().difference(plantingDate!).inDays
      : 0;
}

class CropProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<CropRecord> _crops = [];
  bool _isLoading = false;
  String? _error;

  List<CropRecord> get crops => _crops;
  List<CropRecord> get activeCrops =>
      _crops.where((c) => c.isActive).toList();
  List<CropRecord> get completedCrops =>
      _crops.where((c) => !c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCrops(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _db.database;
      final maps = await db.query(
        'crop_records',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      _crops = maps.map(CropRecord.fromMap).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<CropRecord?> addCrop({
    required String userId,
    required String cropName,
    double? fieldSizeHa,
    DateTime? plantingDate,
    DateTime? expectedHarvestDate,
    String? notes,
  }) async {
    try {
      final db = await _db.database;
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final record = CropRecord(
        id: id,
        userId: userId,
        cropName: cropName,
        fieldSizeHa: fieldSizeHa,
        plantingDate: plantingDate,
        expectedHarvestDate: expectedHarvestDate,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await db.insert('crop_records', record.toMap());
      _crops.insert(0, record);
      notifyListeners();
      return record;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> recordHarvest({
    required String cropId,
    required DateTime harvestDate,
    required double yieldKg,
  }) async {
    try {
      final db = await _db.database;
      await db.update(
        'crop_records',
        {
          'actual_harvest_date': harvestDate.toIso8601String(),
          'yield_kg': yieldKg,
        },
        where: 'id = ?',
        whereArgs: [cropId],
      );
      final index = _crops.indexWhere((c) => c.id == cropId);
      if (index != -1) {
        final old = _crops[index];
        _crops[index] = CropRecord(
          id: old.id,
          userId: old.userId,
          cropName: old.cropName,
          fieldSizeHa: old.fieldSizeHa,
          plantingDate: old.plantingDate,
          expectedHarvestDate: old.expectedHarvestDate,
          actualHarvestDate: harvestDate,
          yieldKg: yieldKg,
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

  Future<void> deleteCrop(String cropId) async {
    try {
      final db = await _db.database;
      await db.delete('crop_records',
          where: 'id = ?', whereArgs: [cropId]);
      _crops.removeWhere((c) => c.id == cropId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}