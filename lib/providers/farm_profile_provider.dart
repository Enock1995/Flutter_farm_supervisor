// lib/providers/farm_profile_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class FarmProfileProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  FarmProfile? _farmProfile;
  bool _isLoading = false;
  String? _error;

  FarmProfile? get farmProfile => _farmProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _farmProfile != null;

  // Load profile from database
  Future<void> loadFarmProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _farmProfile = await _db.getFarmProfile(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save or update farm profile
  Future<void> saveFarmProfile({
    required String userId,
    required double farmSizeHectares,
    required List<String> crops,
    required List<String> livestock,
    required String soilType,
    required String waterSource,
    required bool hasIrrigation,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = FarmProfile(
        userId: userId,
        farmSizeHectares: farmSizeHectares,
        farmSizeCategory: FarmProfile.categoryFromSize(farmSizeHectares),
        crops: crops,
        livestock: livestock,
        soilType: soilType,
        waterSource: waterSource,
        hasIrrigation: hasIrrigation,
        updatedAt: DateTime.now(),
      );

      await _db.saveFarmProfile(profile);
      _farmProfile = profile;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearProfile() {
    _farmProfile = null;
    notifyListeners();
  }
}