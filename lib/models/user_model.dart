// lib/models/user_model.dart
// Represents a registered farmer in the AgricAssist ZW system.

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

  // Base subscription ($2.99 one-time — unlocks 15 core modules forever)
  final bool isSubscribed;
  final DateTime? subscribedAt;

  // Premium subscription ($1.99 / 60 days — unlocks premium modules)
  final bool isPremiumSubscribed;
  final DateTime? premiumExpiresAt;

  // Password reset via security question
  final String? securityQuestion;
  final String? securityAnswerHash;

  final FarmProfile? farmProfile;

  const UserModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.district,
    required this.province,
    required this.agroRegion,
    required this.language,
    required this.registeredAt,
    required this.trialEndsAt,
    this.isSubscribed = false,
    this.subscribedAt,
    this.isPremiumSubscribed = false,
    this.premiumExpiresAt,
    this.securityQuestion,
    this.securityAnswerHash,
    this.farmProfile,
  });

  // Core access = subscribed (base) OR trial still active
  bool get isActive {
    if (isSubscribed) return true;
    return DateTime.now().isBefore(trialEndsAt);
  }

  // Premium access = premium subscribed AND not yet expired
  bool get hasPremiumAccess {
    if (!isPremiumSubscribed) return false;
    if (premiumExpiresAt == null) return false;
    return DateTime.now().isBefore(premiumExpiresAt!);
  }

  // Days until premium expires (0 if expired/not subscribed)
  int get premiumDaysRemaining {
    if (!hasPremiumAccess) return 0;
    final remaining = premiumExpiresAt!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  int get trialDaysRemaining {
    if (isSubscribed) return 0;
    final remaining = trialEndsAt.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  bool get needsSubscription =>
      !isSubscribed && DateTime.now().isAfter(trialEndsAt);

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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      userId: map['user_id'],
      fullName: map['full_name'],
      phone: map['phone'],
      email: map['email'],
      district: map['district'],
      province: map['province'],
      agroRegion: map['agro_region'],
      language: map['language'],
      registeredAt: DateTime.parse(map['registered_at']),
      trialEndsAt: DateTime.parse(map['trial_ends_at']),
      isSubscribed: map['is_subscribed'] == 1,
      subscribedAt: map['subscribed_at'] != null
          ? DateTime.parse(map['subscribed_at'])
          : null,
      isPremiumSubscribed: (map['is_premium_subscribed'] ?? 0) == 1,
      premiumExpiresAt: map['premium_expires_at'] != null
          ? DateTime.parse(map['premium_expires_at'])
          : null,
      securityQuestion: map['security_question'],
      securityAnswerHash: map['security_answer_hash'],
    );
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? language,
    bool? isSubscribed,
    DateTime? subscribedAt,
    bool? isPremiumSubscribed,
    DateTime? premiumExpiresAt,
    String? securityQuestion,
    String? securityAnswerHash,
    FarmProfile? farmProfile,
  }) {
    return UserModel(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      district: district,
      province: province,
      agroRegion: agroRegion,
      language: language ?? this.language,
      registeredAt: registeredAt,
      trialEndsAt: trialEndsAt,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      isPremiumSubscribed: isPremiumSubscribed ?? this.isPremiumSubscribed,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      farmProfile: farmProfile ?? this.farmProfile,
    );
  }

  @override
  String toString() => 'UserModel($userId, $fullName, Region: $agroRegion)';
}

// ---------------------------------------------------------------------------
// FARM PROFILE MODEL
// ---------------------------------------------------------------------------
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

  const FarmProfile({
    required this.userId,
    required this.farmSizeHectares,
    required this.farmSizeCategory,
    required this.crops,
    required this.livestock,
    required this.soilType,
    required this.waterSource,
    required this.hasIrrigation,
    required this.updatedAt,
  });

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
    return FarmProfile(
      userId: map['user_id'],
      farmSizeHectares: (map['farm_size_hectares'] as num).toDouble(),
      farmSizeCategory: map['farm_size_category'],
      crops: (map['crops'] as String)
          .split(',')
          .where((c) => c.isNotEmpty)
          .toList(),
      livestock: (map['livestock'] as String)
          .split(',')
          .where((l) => l.isNotEmpty)
          .toList(),
      soilType: map['soil_type'],
      waterSource: map['water_source'],
      hasIrrigation: map['has_irrigation'] == 1,
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  static String categoryFromSize(double hectares) {
    if (hectares < 5) return 'small';
    if (hectares <= 50) return 'medium';
    return 'large';
  }
}

// ---------------------------------------------------------------------------
// UNKNOWN DISTRICT MODEL
// ---------------------------------------------------------------------------
class UnknownDistrict {
  final String id;
  final String districtName;
  final String? provinceSuggested;
  final String submittedByUserId;
  final DateTime submittedAt;
  final String status;

  const UnknownDistrict({
    required this.id,
    required this.districtName,
    this.provinceSuggested,
    required this.submittedByUserId,
    required this.submittedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'district_name': districtName,
      'province_suggested': provinceSuggested,
      'submitted_by_user_id': submittedByUserId,
      'submitted_at': submittedAt.toIso8601String(),
      'status': status,
    };
  }
}