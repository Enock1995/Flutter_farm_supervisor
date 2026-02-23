// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../constants/app_theme.dart';
import '../constants/zimbabwe_districts.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _db = DatabaseService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

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
    try {
      final normalizedPhone = _normalizePhone(phone);

      // Check phone not already used
      final phoneExists = await _db.isPhoneRegistered(normalizedPhone);
      if (phoneExists) {
        return RegistrationResult.failure(
            'This phone number is already registered.');
      }

      // Determine agro-ecological region
      final regionResult = await _resolveRegion(district, province);
      if (!regionResult.isResolved) {
        return RegistrationResult.unknownDistrict(district);
      }

      final agroRegion = regionResult.region!;

      // Generate User_ID
      final districtCode = ZimbabweDistricts.getDistrictCode(district);
      final userNumber = await _db.getNextUserNumber(districtCode);
      final userId = _generateUserId(districtCode, userNumber);

      // Hash password
      final passwordHash = _hashPassword(password);

      // Build user
      final now = DateTime.now();
      final trialEnd = now.add(const Duration(days: AppConstants.trialDays));

      final newUser = UserModel(
        id: _generateInternalId(),
        userId: userId,
        fullName: fullName.trim(),
        phone: normalizedPhone,
        email: email?.trim(),
        district: district.trim(),
        province: province.trim(),
        agroRegion: agroRegion,
        language: language,
        registeredAt: now,
        trialEndsAt: trialEnd,
        isSubscribed: false,
      );

      // Save to SQLite
      await _db.insertUser(newUser);

      // Save password hash separately
      final db = await _db.database;
      await db.update(
        'users',
        {'password_hash': passwordHash},
        where: 'user_id = ?',
        whereArgs: [newUser.userId],
      );

      // Cache session
      _currentUser = newUser;
      await _saveSession(newUser.userId);

      return RegistrationResult.success(newUser);
    } catch (e) {
      return RegistrationResult.failure(
          'Registration failed: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  Future<LoginResult> login({
    required String phone,
    required String password,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phone);

      // Look up user locally
      final user = await _db.getUserByPhone(normalizedPhone);
      if (user == null) {
        return LoginResult.failure(
            'Phone number not registered. Please create an account first.');
      }

      // Verify password against stored hash
      final passwordHash = _hashPassword(password);
      final db = await _db.database;
      final result = await db.query(
        'users',
        where: 'phone = ? AND password_hash = ?',
        whereArgs: [normalizedPhone, passwordHash],
        limit: 1,
      );

      if (result.isEmpty) {
        return LoginResult.failure('Incorrect password. Please try again.');
      }

      // Save session
      _currentUser = user;
      await _saveSession(user.userId);

      return LoginResult.success(user);
    } catch (e) {
      return LoginResult.failure('Login failed: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    _currentUser = null;
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyUserId);
  }

  // ---------------------------------------------------------------------------
  // RESTORE SESSION ON APP START
  // ---------------------------------------------------------------------------
  Future<UserModel?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
      if (!isLoggedIn) return null;

      final userId = prefs.getString(AppConstants.keyUserId);
      if (userId == null) return null;

      final user = await _db.getUserByPublicId(userId);
      if (user != null) {
        _currentUser = user;
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // DISTRICT REGION RESOLUTION
  // ---------------------------------------------------------------------------
  Future<_RegionResult> _resolveRegion(
      String district, String province) async {
    // Check hardcoded master map
    final region = ZimbabweDistricts.getRegion(district);
    if (region != null) {
      return _RegionResult(region: region, isResolved: true);
    }

    // Check locally learned districts
    final learned = await _db.getLearnedDistrict(district);
    if (learned != null) {
      return _RegionResult(
          region: learned['agro_region'], isResolved: true);
    }

    return _RegionResult(isResolved: false);
  }

  // ---------------------------------------------------------------------------
  // USER_ID GENERATION
  // ---------------------------------------------------------------------------
  String _generateUserId(String districtCode, int number) {
    final paddedNumber =
        number.toString().padLeft(AppConstants.userIdLength, '0');
    return '${AppConstants.userIdPrefix}-${districtCode.toUpperCase()}-$paddedNumber';
  }

  String _generateInternalId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _normalizePhone(String phone) {
    phone = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('0')) phone = '263${phone.substring(1)}';
    if (!phone.startsWith('263')) phone = '263$phone';
    return phone;
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserId, userId);
  }

  // Backend sync — disabled until server is ready
  Future<void> _syncRegistrationToBackend(
      UserModel user, String passwordHash) async {
    return;
  }
}

// ---------------------------------------------------------------------------
// RESULT CLASSES
// ---------------------------------------------------------------------------
class RegistrationResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;
  final bool isUnknownDistrict;
  final String? unknownDistrictName;

  const RegistrationResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.isUnknownDistrict = false,
    this.unknownDistrictName,
  });

  factory RegistrationResult.success(UserModel user) =>
      RegistrationResult._(isSuccess: true, user: user);

  factory RegistrationResult.failure(String message) =>
      RegistrationResult._(isSuccess: false, errorMessage: message);

  factory RegistrationResult.unknownDistrict(String districtName) =>
      RegistrationResult._(
        isSuccess: false,
        isUnknownDistrict: true,
        unknownDistrictName: districtName,
        errorMessage:
            'District "$districtName" is not in our system yet. It will be reviewed and added.',
      );
}

class LoginResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;

  const LoginResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory LoginResult.success(UserModel user) =>
      LoginResult._(isSuccess: true, user: user);

  factory LoginResult.failure(String message) =>
      LoginResult._(isSuccess: false, errorMessage: message);
}

class _RegionResult {
  final String? region;
  final bool isResolved;
  const _RegionResult({this.region, required this.isResolved});
}