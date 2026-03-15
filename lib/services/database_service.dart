// lib/services/database_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db_init_stub.dart'
    if (dart.library.ffi) 'db_init_desktop.dart';

import '../constants/app_theme.dart';
import '../models/user_model.dart';
import 'farm_management_database_service.dart';
import 'task_activity_database_service.dart';
import 'payroll_fieldreport_database_service.dart';
import 'sos_database_service.dart';
import 'mudhumeni_database_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  static bool _factoryInitialised = false;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!_factoryInitialised) {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        await initDatabaseFactory();
      }
      _factoryInitialised = true;
    }
    final String dbPath = await _resolveDbPath();
    return await openDatabase(
      dbPath,
      version: 8,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> _resolveDbPath() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      final Directory appDir = await getApplicationSupportDirectory();
      await appDir.create(recursive: true);
      return p.join(appDir.path, AppConstants.dbName);
    }
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbDir = p.join(docsDir.path, 'agricassist');
    await Directory(dbDir).create(recursive: true);
    final String fullPath = p.join(dbDir, AppConstants.dbName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_path', fullPath);
    return fullPath;
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        user_id TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        email TEXT,
        district TEXT NOT NULL,
        province TEXT NOT NULL,
        agro_region TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        registered_at TEXT NOT NULL,
        trial_ends_at TEXT NOT NULL,
        is_subscribed INTEGER NOT NULL DEFAULT 0,
        subscribed_at TEXT,
        is_premium_subscribed INTEGER NOT NULL DEFAULT 0,
        premium_expires_at TEXT,
        security_question TEXT,
        security_answer_hash TEXT,
        password_hash TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE farm_profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        farm_size_hectares REAL NOT NULL,
        farm_size_category TEXT NOT NULL,
        crops TEXT NOT NULL DEFAULT '',
        livestock TEXT NOT NULL DEFAULT '',
        soil_type TEXT NOT NULL,
        water_source TEXT NOT NULL,
        has_irrigation INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE unknown_districts (
        id TEXT PRIMARY KEY,
        district_name TEXT NOT NULL,
        province_suggested TEXT,
        submitted_by_user_id TEXT NOT NULL,
        submitted_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        region_assigned TEXT,
        verified_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE learned_districts (
        district_name TEXT PRIMARY KEY,
        province TEXT NOT NULL,
        agro_region TEXT NOT NULL,
        district_code TEXT NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_id_counter (
        district_code TEXT PRIMARY KEY,
        next_number INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE advisory_tips (
        id TEXT PRIMARY KEY,
        region TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        season TEXT,
        is_urgent INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE crop_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        crop_name TEXT NOT NULL,
        field_size_ha REAL,
        planting_date TEXT,
        expected_harvest_date TEXT,
        actual_harvest_date TEXT,
        yield_kg REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE livestock_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        animal_type TEXT NOT NULL,
        count INTEGER NOT NULL,
        breed TEXT,
        notes TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS finance_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        crop_or_animal TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_diagnosis_history (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        subject_type TEXT NOT NULL,
        crop_or_animal TEXT NOT NULL DEFAULT '',
        symptoms TEXT NOT NULL,
        diagnosis TEXT NOT NULL,
        confidence TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT NOT NULL,
        treatment TEXT NOT NULL DEFAULT '[]',
        prevention TEXT NOT NULL DEFAULT '[]',
        local_products TEXT NOT NULL DEFAULT '',
        see_expert INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_yield_history (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        field_size_ha REAL NOT NULL,
        predicted_yield_per_ha REAL NOT NULL,
        total_predicted_tonnes REAL NOT NULL,
        confidence TEXT NOT NULL,
        zim_average_per_ha REAL NOT NULL,
        comparison TEXT NOT NULL,
        comparison_percent INTEGER NOT NULL DEFAULT 0,
        limiting_factors TEXT NOT NULL DEFAULT '[]',
        recommendations TEXT NOT NULL DEFAULT '[]',
        harvest_window TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_chat_history (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    await FarmManagementDatabaseService.createTables(db);
    await PayrollFieldReportDatabaseService.createTables(db);
    await SosDatabaseService.createTables(db);
    await MudhumeniDatabaseService.createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS ai_diagnosis_history (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, subject_type TEXT NOT NULL, crop_or_animal TEXT NOT NULL DEFAULT \'\', symptoms TEXT NOT NULL, diagnosis TEXT NOT NULL, confidence TEXT NOT NULL, severity TEXT NOT NULL, description TEXT NOT NULL, treatment TEXT NOT NULL DEFAULT \'[]\', prevention TEXT NOT NULL DEFAULT \'[]\', local_products TEXT NOT NULL DEFAULT \'\', see_expert INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE IF NOT EXISTS ai_yield_history (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, crop_type TEXT NOT NULL, field_size_ha REAL NOT NULL, predicted_yield_per_ha REAL NOT NULL, total_predicted_tonnes REAL NOT NULL, confidence TEXT NOT NULL, zim_average_per_ha REAL NOT NULL, comparison TEXT NOT NULL, comparison_percent INTEGER NOT NULL DEFAULT 0, limiting_factors TEXT NOT NULL DEFAULT \'[]\', recommendations TEXT NOT NULL DEFAULT \'[]\', harvest_window TEXT NOT NULL DEFAULT \'\', created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE IF NOT EXISTS ai_chat_history (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, role TEXT NOT NULL, content TEXT NOT NULL, created_at TEXT NOT NULL)');
    }
    if (oldVersion < 3) {
      await FarmManagementDatabaseService.createTables(db);
    }
    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE users ADD COLUMN is_premium_subscribed INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE users ADD COLUMN premium_expires_at TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE users ADD COLUMN security_question TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE users ADD COLUMN security_answer_hash TEXT'); } catch (_) {}
    }
    if (oldVersion < 5) {
      await TaskActivityDatabaseService.createTables(db);
    }
    if (oldVersion < 6) {
      await PayrollFieldReportDatabaseService.createTables(db);
    }
    if (oldVersion < 7) {
      await SosDatabaseService.createTables(db);
    }
    if (oldVersion < 8) {
      await MudhumeniDatabaseService.createTables(db);
    }
  }

  // USER OPERATIONS — unchanged
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    final db = await database;
    final maps = await db.query('users',
        where: 'phone = ?', whereArgs: [phone], limit: 1);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserByPublicId(String userId) async {
    final db = await database;
    final maps = await db.query('users',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<bool> isPhoneRegistered(String phone) async {
    final db = await database;
    final result = await db.query('users',
        columns: ['id'],
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1);
    return result.isNotEmpty;
  }

  Future<void> updateSubscription(String userId, bool isSubscribed) async {
    final db = await database;
    await db.update(
      'users',
      {
        'is_subscribed': isSubscribed ? 1 : 0,
        'subscribed_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> activatePremium(String userId) async {
    final db = await database;
    final expiresAt = DateTime.now()
        .add(const Duration(days: 60))
        .toIso8601String();
    await db.update(
      'users',
      {
        'is_premium_subscribed': 1,
        'premium_expires_at': expiresAt,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updatePassword(String phone, String newPasswordHash) async {
    final db = await database;
    await db.update(
      'users',
      {'password_hash': newPasswordHash},
      where: 'phone = ?',
      whereArgs: [phone],
    );
  }

  Future<int> getNextUserNumber(String districtCode) async {
    final db = await database;
    final code = districtCode.toUpperCase();
    final existing = await db.query('user_id_counter',
        where: 'district_code = ?', whereArgs: [code], limit: 1);
    if (existing.isEmpty) {
      await db.insert('user_id_counter',
          {'district_code': code, 'next_number': 2});
      return 1;
    }
    final current = existing.first['next_number'] as int;
    await db.update('user_id_counter', {'next_number': current + 1},
        where: 'district_code = ?', whereArgs: [code]);
    return current;
  }

  Future<void> submitUnknownDistrict(UnknownDistrict district) async {
    final db = await database;
    await db.insert('unknown_districts', district.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Map<String, dynamic>?> getLearnedDistrict(String districtName) async {
    final db = await database;
    final key = districtName.trim().toLowerCase();
    final result = await db.query('learned_districts',
        where: 'LOWER(district_name) = ?', whereArgs: [key], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  Future<void> saveLearnedDistrict({
    required String districtName,
    required String province,
    required String agroRegion,
    required String districtCode,
  }) async {
    final db = await database;
    await db.insert(
      'learned_districts',
      {
        'district_name': districtName,
        'province': province,
        'agro_region': agroRegion,
        'district_code': districtCode,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveFarmProfile(FarmProfile profile) async {
    final db = await database;
    final existing = await db.query('farm_profiles',
        where: 'user_id = ?', whereArgs: [profile.userId], limit: 1);
    final map = profile.toMap()..['id'] = profile.userId;
    if (existing.isEmpty) {
      await db.insert('farm_profiles', map);
    } else {
      await db.update('farm_profiles', map,
          where: 'user_id = ?', whereArgs: [profile.userId]);
    }
  }

  Future<FarmProfile?> getFarmProfile(String userId) async {
    final db = await database;
    final maps = await db.query('farm_profiles',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (maps.isEmpty) return null;
    return FarmProfile.fromMap(maps.first);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('farm_profiles');
    await db.delete('unknown_districts');
    await db.delete('user_id_counter');
    await db.delete('learned_districts');
  }
}