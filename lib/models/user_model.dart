// lib/models/user_model.dart
// Developed by Sir Enocks Cor Technologies

import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String? email;
  final String district;
  final String province;
  final String agroRegion;
  final String language;
  final DateTime registeredAt;
  final DateTime trialEndsAt;
  final bool isSubscribed;
  final DateTime? subscribedAt;
  final bool isPremiumSubscribed;
  final DateTime? premiumExpiresAt;
  final String? securityQuestion;
  final String? securityAnswerHash;
  final String? passwordHash;
  final String role;
  final String ward;

  UserModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.district,
    required this.province,
    required this.agroRegion,
    this.language = 'en',
    required this.registeredAt,
    required this.trialEndsAt,
    this.isSubscribed = false,
    this.subscribedAt,
    this.isPremiumSubscribed = false,
    this.premiumExpiresAt,
    this.securityQuestion,
    this.securityAnswerHash,
    this.passwordHash,
    this.role = 'farmer',
    this.ward = '',
  });

  bool get hasPremiumAccess {
    if (!isPremiumSubscribed) return false;
    if (premiumExpiresAt == null) return false;
    return DateTime.now().isBefore(premiumExpiresAt!);
  }

  // ── ROLE GETTERS ──────────────────────────────────────────────────────────
  
  String get normalizedRole {
    final r = role.toLowerCase().trim();
    if (r == 'admin') return 'national_admin';
    if (r == 'veterinary_officer') return 'vet';
    return r;
  }

  bool get isFarmer => normalizedRole == 'farmer';
  bool get isMudhumeni => normalizedRole == 'mudhumeni';
  bool get isVet => normalizedRole == 'vet';
  bool get isDistrictAdmin => normalizedRole == 'district_admin';
  bool get isProvincialAdmin => normalizedRole == 'provincial_admin';
  bool get isNationalAdmin => normalizedRole == 'national_admin';

  bool get isAdmin => isDistrictAdmin || isProvincialAdmin || isNationalAdmin;
  
  bool get isAnyAuthority => isMudhumeni || isVet || isAdmin;

  int get authorityRank {
    switch (normalizedRole) {
      case 'national_admin': return 5;
      case 'provincial_admin': return 4;
      case 'district_admin': return 3;
      case 'mudhumeni': return 2;
      case 'vet': return 2;
      case 'farmer': return 1;
      default: return 0;
    }
  }

  String get roleLabel {
    switch (normalizedRole) {
      case 'national_admin': return 'National Admin';
      case 'provincial_admin': return 'Provincial Admin';
      case 'district_admin': return 'District Admin';
      case 'mudhumeni': return 'Mudhumeni Officer';
      case 'vet': return 'Veterinary Officer';
      case 'farmer': return 'Farmer';
      default: return 'User';
    }
  }

  String get roleEmoji {
    switch (normalizedRole) {
      case 'national_admin': return '🏛️';
      case 'provincial_admin': return '🏢';
      case 'district_admin': return '🏬';
      case 'mudhumeni': return '🌿';
      case 'vet': return '🩺';
      case 'farmer': return '👨‍🌾';
      default: return '👤';
    }
  }

  // ── MUDHUMENI & VET PERMISSIONS ───────────────────────────────────────────
  
  bool get canCreateKnowledgePosts => isMudhumeni || isVet || isAdmin;
  bool get canAnswerWithBadge => isMudhumeni || isVet || isAdmin;
  bool get canReplyPrivateQa => isMudhumeni || isVet || isAdmin;
  bool get canManageArea => isMudhumeni || isAdmin;
  bool get canConfirmFieldVisit => isMudhumeni || isAdmin;
  bool get canAddSeasonalEntry => isMudhumeni || isAdmin;
  bool get canResolveProblem => isMudhumeni || isAdmin;
  bool get canDeleteOthersPosts => isAdmin;
  bool get canViewWardFarmers => isMudhumeni || isAdmin;
  
  int get trialDaysRemaining {
    final now = DateTime.now();
    if (now.isAfter(trialEndsAt)) return 0;
    return trialEndsAt.difference(now).inDays;
  }

  int get premiumDaysRemaining {
    if (!isPremiumSubscribed || premiumExpiresAt == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(premiumExpiresAt!)) return 0;
    return premiumExpiresAt!.difference(now).inDays;
  }

  // ── HIERARCHY MANAGEMENT ──────────────────────────────────────────────────

  bool canManageUser(UserModel other) {
    if (authorityRank <= other.authorityRank) return false;
    
    switch (normalizedRole) {
      case 'national_admin':
        return true;
      case 'provincial_admin':
        return province == other.province;
      case 'district_admin':
        return district == other.district;
      case 'mudhumeni':
        return ward == other.ward && other.isFarmer;
      default:
        return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'district': district,
      'province': province,
      'agro_region': agroRegion,
      'language': language,
      'registered_at': registeredAt.toIso8601String(),
      'trial_ends_at': trialEndsAt.toIso8601String(),
      'is_subscribed': isSubscribed ? 1 : 0,
      'subscribed_at': subscribedAt?.toIso8601String(),
      'is_premium_subscribed': isPremiumSubscribed ? 1 : 0,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'security_question': securityQuestion,
      'security_answer_hash': securityAnswerHash,
      'password_hash': passwordHash,
      'role': role,
      'ward': ward,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      district: map['district'] as String,
      province: map['province'] as String,
      agroRegion: map['agro_region'] as String,
      language: map['language'] as String? ?? 'en',
      registeredAt: DateTime.parse(map['registered_at'] as String),
      trialEndsAt: DateTime.parse(map['trial_ends_at'] as String),
      isSubscribed: (map['is_subscribed'] as int) == 1,
      subscribedAt: map['subscribed_at'] != null
          ? DateTime.parse(map['subscribed_at'] as String)
          : null,
      isPremiumSubscribed: (map['is_premium_subscribed'] as int? ?? 0) == 1,
      premiumExpiresAt: map['premium_expires_at'] != null
          ? DateTime.parse(map['premium_expires_at'] as String)
          : null,
      securityQuestion: map['security_question'] as String?,
      securityAnswerHash: map['security_answer_hash'] as String?,
      passwordHash: map['password_hash'] as String?,
      role: map['role'] as String? ?? 'farmer',
      ward: map['ward'] as String? ?? '',
    );
  }

  UserModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? email,
    String? district,
    String? province,
    String? agroRegion,
    String? language,
    DateTime? registeredAt,
    DateTime? trialEndsAt,
    bool? isSubscribed,
    DateTime? subscribedAt,
    bool? isPremiumSubscribed,
    DateTime? premiumExpiresAt,
    String? securityQuestion,
    String? securityAnswerHash,
    String? passwordHash,
    String? role,
    String? ward,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      district: district ?? this.district,
      province: province ?? this.province,
      agroRegion: agroRegion ?? this.agroRegion,
      language: language ?? this.language,
      registeredAt: registeredAt ?? this.registeredAt,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      isPremiumSubscribed: isPremiumSubscribed ?? this.isPremiumSubscribed,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      ward: ward ?? this.ward,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUPPORTING MODELS
// ══════════════════════════════════════════════════════════════════════════════

class FarmProfile {
  final String userId;
  final double farmSizeHectares;
  final String farmSizeCategory;
  final List<String> crops;
  final List<String> livestock;
  final String soilType;
  final String waterSource;
  final bool hasIrrigation;
  final DateTime updatedAt;

  FarmProfile({
    required this.userId,
    required this.farmSizeHectares,
    required this.farmSizeCategory,
    required this.crops,
    required this.livestock,
    required this.soilType,
    required this.waterSource,
    this.hasIrrigation = false,
    required this.updatedAt,
  });

  static String categoryFromSize(double hectares) {
    if (hectares < 1) return 'Small Scale';
    if (hectares < 5) return 'Medium Scale';
    if (hectares < 20) return 'Large Scale';
    return 'Commercial';
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'farm_size_hectares': farmSizeHectares,
      'farm_size_category': farmSizeCategory,
      'crops': crops.join(','),
      'livestock': livestock.join(','),
      'soil_type': soilType,
      'water_source': waterSource,
      'has_irrigation': hasIrrigation ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FarmProfile.fromMap(Map<String, dynamic> map) {
    final cropsString = map['crops'] as String? ?? '';
    final livestockString = map['livestock'] as String? ?? '';

    return FarmProfile(
      userId: map['user_id'] as String,
      farmSizeHectares: (map['farm_size_hectares'] as num).toDouble(),
      farmSizeCategory: map['farm_size_category'] as String,
      crops: cropsString.isEmpty ? [] : cropsString.split(','),
      livestock: livestockString.isEmpty ? [] : livestockString.split(','),
      soilType: map['soil_type'] as String,
      waterSource: map['water_source'] as String,
      hasIrrigation: (map['has_irrigation'] as int) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class UnknownDistrict {
  final String id;
  final String districtName;
  final String? provinceSuggested;
  final String submittedByUserId;
  final DateTime submittedAt;

  UnknownDistrict({
    required this.id,
    required this.districtName,
    this.provinceSuggested,
    required this.submittedByUserId,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'district_name': districtName,
      'province_suggested': provinceSuggested,
      'submitted_by_user_id': submittedByUserId,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }
}

class RoleNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String reason;
  final String fromRole;
  final String fromName;
  final DateTime createdAt;
  final bool isRead;

  RoleNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.reason = '',
    this.fromRole = '',
    this.fromName = '',
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'reason': reason,
      'from_role': fromRole,
      'from_name': fromName,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory RoleNotification.fromMap(Map<String, dynamic> map) {
    return RoleNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      reason: map['reason'] as String? ?? '',
      fromRole: map['from_role'] as String? ?? '',
      fromName: map['from_name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }
}