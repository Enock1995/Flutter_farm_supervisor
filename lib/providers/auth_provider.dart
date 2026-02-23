// lib/providers/auth_provider.dart
// Bridges AuthService with the UI using Provider state management.
// Any widget in the tree can listen to auth state changes via this provider.

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,      // App just started, checking session
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  // Getters (UI reads these)
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ---------------------------------------------------------------------------
  // CHECK SESSION ON APP START
  // ---------------------------------------------------------------------------
  Future<void> checkSession() async {
    _status = AuthStatus.initial;
    notifyListeners();

    final user = await _authService.restoreSession();

    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
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
  }) async {
    _setLoading();

    final result = await _authService.register(
      fullName: fullName,
      phone: phone,
      password: password,
      district: district,
      province: province,
      email: email,
      language: language,
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
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CLEAR ERROR
  // ---------------------------------------------------------------------------
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // INTERNAL
  // ---------------------------------------------------------------------------
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }
}