// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../config/app_config.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  List<RoleNotification> _pendingNotifications = [];

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  List<RoleNotification> get pendingNotifications => _pendingNotifications;
  bool get hasNotifications => _pendingNotifications.isNotEmpty;

  // ── Role getters ──────────────────────────────────────
  String get userRole => _user?.normalizedRole ?? 'farmer';

  bool get isFarmer         => _user?.isFarmer ?? true;
  bool get isMudhumeni      => _user?.isMudhumeni ?? false;
  bool get isDistrictAdmin  => _user?.isDistrictAdmin ?? false;
  bool get isProvincialAdmin => _user?.isProvincialAdmin ?? false;
  bool get isNationalAdmin  {
    if (_user == null) return false;
    if (_user!.isNationalAdmin) return true;
    // Fallback: hardcoded phone (legacy 'admin' role also maps here)
    return _user!.phone == AppConfig.adminPhoneNumber;
  }

  // isAdmin = any admin level (district, provincial, national)
  bool get isAdmin => isDistrictAdmin || isProvincialAdmin || isNationalAdmin;

  // isAnyAuthority = mudhumeni or higher
  bool get isAnyAuthority => isMudhumeni || isAdmin;

  // Capability getters delegated to model
  bool get canCreateKnowledgePosts => _user?.canCreateKnowledgePosts ?? false;
  bool get canAnswerWithBadge      => _user?.canAnswerWithBadge ?? false;
  bool get canReplyPrivateQa       => _user?.canReplyPrivateQa ?? false;
  bool get canManageArea           => _user?.canManageArea ?? false;
  bool get canConfirmFieldVisit    => _user?.canConfirmFieldVisit ?? false;
  bool get canAddSeasonalEntry     => _user?.canAddSeasonalEntry ?? false;
  bool get canResolveProblem       => _user?.canResolveProblem ?? false;
  bool get canDeleteOthersPosts    => _user?.canDeleteOthersPosts ?? false;
  bool get canAccessAdminPanel     => isAdmin;
  bool get canViewWardFarmers      => _user?.canViewWardFarmers ?? false;

  // ── Area of influence ─────────────────────────────────
  String get authorityProvince => _user?.province ?? '';
  String get authorityDistrict => _user?.district ?? '';
  String get authorityWard     => _user?.ward ?? '';

  // ---------------------------------------------------------------------------
  // CHECK SESSION
  // ---------------------------------------------------------------------------
  Future<void> checkSession() async {
    _status = AuthStatus.initial;
    notifyListeners();
    final user = await _authService.restoreSession();
    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
      await _loadNotifications();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // REGISTER
  // ---------------------------------------------------------------------------
  Future<RegistrationResult> register({
    required String fullName,
    required String phone,
    required String password,
    required String district,
    required String province,
    String? email,
    String language = 'en',
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    _setLoading();
    final result = await _authService.register(
      fullName: fullName, phone: phone, password: password,
      district: district, province: province, email: email,
      language: language, securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );
    if (result.isSuccess) {
      _user = result.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result.errorMessage;
    }
    notifyListeners();
    return result;
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  Future<LoginResult> login({
    required String phone,
    required String password,
  }) async {
    _setLoading();
    final result = await _authService.login(phone: phone, password: password);
    if (result.isSuccess) {
      _user = result.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      await _loadNotifications();
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result.errorMessage;
    }
    notifyListeners();
    return result;
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _pendingNotifications = [];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTIONS
  // ---------------------------------------------------------------------------
  Future<void> activateBaseSubscription() async {
    if (_user == null) return;
    await DatabaseService().updateSubscription(_user!.userId, true);
    _user = _user!.copyWith(isSubscribed: true, subscribedAt: DateTime.now());
    notifyListeners();
  }

  Future<void> activatePremiumSubscription() async {
    if (_user == null) return;
    await DatabaseService().activatePremium(_user!.userId);
    _user = _user!.copyWith(
      isPremiumSubscribed: true,
      premiumExpiresAt: DateTime.now().add(const Duration(days: 60)),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // PASSWORD RESET
  // ---------------------------------------------------------------------------
  Future<String?> getSecurityQuestion(String phone) async =>
      await _authService.getSecurityQuestion(phone);

  Future<bool> verifySecurityAnswer(String phone, String answer) async =>
      await _authService.verifySecurityAnswer(phone, answer);

  Future<bool> resetPassword(String phone, String newPassword) async =>
      await _authService.resetPassword(phone, newPassword);

  // ---------------------------------------------------------------------------
  // PROFILE UPDATES
  // ---------------------------------------------------------------------------
  Future<void> updateFullName(String name) async {
    final db = await _authService.getDatabase();
    await db.update('users', {'full_name': name},
        where: 'user_id = ?', whereArgs: [_user!.userId]);
    _user = _user!.copyWith(fullName: name);
    notifyListeners();
  }

  Future<bool> changePassword(String current, String newPass) async {
    final db = await _authService.getDatabase();
    final hash = _authService.hashPassword(current);
    final rows = await db.query('users',
        where: 'user_id = ? AND password_hash = ?',
        whereArgs: [_user!.userId, hash]);
    if (rows.isEmpty) return false;
    await db.update('users',
        {'password_hash': _authService.hashPassword(newPass)},
        where: 'user_id = ?', whereArgs: [_user!.userId]);
    return true;
  }

  Future<void> deleteAccount() async {
    final db = await _authService.getDatabase();
    final userId = _user!.userId;
    for (final table in [
      'users', 'farm_profiles', 'crops', 'livestock',
      'finance_records', 'labour_sessions', 'irrigation_setups',
      'irrigation_logs', 'soil_records', 'farm_alerts', 'saved_calculations'
    ]) {
      try {
        await db.delete(table, where: 'user_id = ?', whereArgs: [userId]);
      } catch (_) {}
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ROLE MANAGEMENT
  // ---------------------------------------------------------------------------

  /// Update a user's role. Called by admin panel after appoint/demote actions.
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await DatabaseService().updateUserRole(userId, newRole);
      // Refresh current user if it's them
      if (_user?.userId == userId) {
        _user = _user!.copyWith(role: newRole);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider.updateUserRole error: $e');
    }
  }

  /// Delete a user by userId. Sends notification before deleting.
  Future<void> deleteUserById(String userId) async {
    try {
      await DatabaseService().deleteUser(userId);
    } catch (e) {
      debugPrint('AuthProvider.deleteUserById error: $e');
    }
  }

  /// Refreshes current user from DB.
  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final db = await _authService.getDatabase();
      final rows = await db.query('users',
          where: 'user_id = ?', whereArgs: [_user!.userId], limit: 1);
      if (rows.isNotEmpty) {
        _user = UserModel.fromMap(rows.first);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider.refreshUser error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // WARD MANAGEMENT
  // ---------------------------------------------------------------------------
  Future<void> updateUserWard(String ward) async {
    if (_user == null) return;
    try {
      await DatabaseService().updateUserWard(_user!.userId, ward);
      _user = _user!.copyWith(ward: ward);
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider.updateUserWard error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------
  Future<void> _loadNotifications() async {
    if (_user == null) return;
    try {
      _pendingNotifications = await DatabaseService()
          .getUnreadNotifications(_user!.userId);
    } catch (e) {
      debugPrint('AuthProvider._loadNotifications error: $e');
    }
  }

  Future<void> markNotificationsRead() async {
    if (_user == null) return;
    await DatabaseService().markNotificationsRead(_user!.userId);
    _pendingNotifications = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }
}