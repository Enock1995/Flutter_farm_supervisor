// lib/providers/input_calculator_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/input_calculator_service.dart';

class InputCalculatorProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<SavedCalculation> _saved = [];
  bool _isLoading = false;
  String? _error;

  List<SavedCalculation> get saved => _saved;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saved_calculations (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          summary TEXT NOT NULL,
          saved_at TEXT NOT NULL,
          inputs TEXT NOT NULL
        )
      ''');
      final maps = await db.query(
        'saved_calculations',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'saved_at DESC',
        limit: 50,
      );
      _saved =
          maps.map(SavedCalculation.fromMap).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveCalculation({
    required String userId,
    required String type,
    required String title,
    required String summary,
    required Map<String, dynamic> inputs,
  }) async {
    final id =
        'calc_${DateTime.now().millisecondsSinceEpoch}';
    final calc = SavedCalculation(
      id: id,
      userId: userId,
      type: type,
      title: title,
      summary: summary,
      savedAt: DateTime.now(),
      inputs: inputs,
    );
    try {
      final db = await _db.database;
      await db.insert(
          'saved_calculations', calc.toMap());
      _saved.insert(0, calc);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCalculation(String id) async {
    _saved.removeWhere((c) => c.id == id);
    notifyListeners();
    try {
      final db = await _db.database;
      await db.delete('saved_calculations',
          where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }
}