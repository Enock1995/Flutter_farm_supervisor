// lib/providers/livestock_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class LivestockRecord {
  final String id;
  final String userId;
  final String animalType;
  int count;
  final String? breed;
  String? notes;
  final DateTime updatedAt;

  LivestockRecord({
    required this.id,
    required this.userId,
    required this.animalType,
    required this.count,
    this.breed,
    this.notes,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'animal_type': animalType,
        'count': count,
        'breed': breed,
        'notes': notes,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory LivestockRecord.fromMap(Map<String, dynamic> m) =>
      LivestockRecord(
        id: m['id'],
        userId: m['user_id'],
        animalType: m['animal_type'],
        count: m['count'] as int,
        breed: m['breed'],
        notes: m['notes'],
        updatedAt: DateTime.parse(m['updated_at']),
      );
}

class LivestockProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<LivestockRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  List<LivestockRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalAnimals =>
      _records.fold(0, (sum, r) => sum + r.count);

  Future<void> loadLivestock(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      final maps = await db.query(
        'livestock_records',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'animal_type ASC',
      );
      _records = maps.map(LivestockRecord.fromMap).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLivestock({
    required String userId,
    required String animalType,
    required int count,
    String? breed,
    String? notes,
  }) async {
    try {
      final db = await _db.database;

      // Check if same animal type already exists
      final existing = _records
          .where((r) => r.animalType == animalType)
          .toList();

      if (existing.isNotEmpty) {
        // Update count instead of duplicate
        final record = existing.first;
        final newCount = record.count + count;
        await db.update(
          'livestock_records',
          {
            'count': newCount,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [record.id],
        );
        record.count = newCount;
      } else {
        final id =
            DateTime.now().millisecondsSinceEpoch.toString();
        final record = LivestockRecord(
          id: id,
          userId: userId,
          animalType: animalType,
          count: count,
          breed: breed,
          notes: notes,
          updatedAt: DateTime.now(),
        );
        await db.insert('livestock_records', record.toMap());
        _records.add(record);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCount(String id, int newCount) async {
    try {
      if (newCount <= 0) {
        await deleteLivestock(id);
        return;
      }
      final db = await _db.database;
      await db.update(
        'livestock_records',
        {
          'count': newCount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      final index = _records.indexWhere((r) => r.id == id);
      if (index != -1) {
        _records[index].count = newCount;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteLivestock(String id) async {
    try {
      final db = await _db.database;
      await db.delete('livestock_records',
          where: 'id = ?', whereArgs: [id]);
      _records.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}