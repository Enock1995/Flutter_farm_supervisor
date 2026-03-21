// lib/models/user_model.dart
// Represents a registered user in the AgricAssist ZW system.

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

  // Base subscription ($2.99 one-time)
  final bool isSubscribed;
  final DateTime? subscribedAt;

  // Premium subscription ($1.99 / 60 days)
  final bool isPremiumSubscribed;
  final DateTime? premiumExpiresAt;

  // Password reset
  final String? securityQuestion;
  final String? securityAnswerHash;

  // Role hierarchy:
  //   'farmer' | 'mudhumeni' | 'district_admin' | 'provincial_admin' | 'national_admin'
  // Legacy 'admin' maps to 'national_admin' via getter
  final String role;

  // Ward — links farmer/mudhumeni to their locality
  final String ward;

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
    this.role = 'farmer',
    this.ward = '',
    this.farmProfile,
  });

  // ── Subscription helpers ──────────────────────────────
  bool get isActive {
    if (isSubscribed) return true;
    return DateTime.now().isBefore(trialEndsAt);
  }

  bool get hasPremiumAccess {
    if (!isPremiumSubscribed) return false;
    if (premiumExpiresAt == null) return false;
    return DateTime.now().isBefore(premiumExpiresAt!);
  }

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

  bool get hasWard => ward.trim().isNotEmpty;

  // ── Role hierarchy getters ────────────────────────────
  // Normalise legacy 'admin' → national_admin
  String get normalizedRole =>
      role == 'admin' ? 'national_admin' : role;

  bool get isFarmer        => normalizedRole == 'farmer';
  bool get isMudhumeni     => normalizedRole == 'mudhumeni';
  bool get isDistrictAdmin => normalizedRole == 'district_admin';
  bool get isProvincialAdmin => normalizedRole == 'provincial_admin';
  bool get isNationalAdmin => normalizedRole == 'national_admin';

  // isAdmin = any authority level above mudhumeni (for legacy compat)
  bool get isAdmin =>
      isDistrictAdmin || isProvincialAdmin || isNationalAdmin;

  // isAnyAuthority = mudhumeni or above (can access admin features)
  bool get isAnyAuthority => isMudhumeni || isAdmin;

  // Numeric rank — higher = more authority (used for hierarchy checks)
  int get authorityRank {
    switch (normalizedRole) {
      case 'national_admin':   return 5;
      case 'provincial_admin': return 4;
      case 'district_admin':   return 3;
      case 'mudhumeni':        return 2;
      default:                 return 1; // farmer
    }
  }

  // Can this user manage (appoint/demote/delete) another user?
  bool canManageUser(UserModel other) {
    // Cannot manage yourself
    if (userId == other.userId) return false;
    // Must outrank the other user
    return authorityRank > other.authorityRank;
  }

  // Display label for role
  String get roleLabel {
    switch (normalizedRole) {
      case 'national_admin':   return 'National Admin';
      case 'provincial_admin': return 'Provincial Admin';
      case 'district_admin':   return 'District Admin';
      case 'mudhumeni':        return 'Mudhumeni Officer';
      default:                 return 'Farmer';
    }
  }

  String get roleEmoji {
    switch (normalizedRole) {
      case 'national_admin':   return '🏛️';
      case 'provincial_admin': return '🏢';
      case 'district_admin':   return '🏬';
      case 'mudhumeni':        return '🌿';
      default:                 return '👨‍🌾';
    }
  }

  // ── Capability getters (unchanged) ───────────────────
  bool get canCreateKnowledgePosts => isMudhumeni || isAdmin;
  bool get canAnswerWithBadge      => isMudhumeni || isAdmin;
  bool get canReplyPrivateQa       => isMudhumeni || isAdmin;
  bool get canManageArea           => isMudhumeni || isAdmin;
  bool get canConfirmFieldVisit    => isMudhumeni || isAdmin;
  bool get canAddSeasonalEntry     => isMudhumeni || isAdmin;
  bool get canResolveProblem       => isMudhumeni || isAdmin;
  bool get canDeleteOthersPosts    => isMudhumeni || isAdmin;
  bool get canAccessAdminPanel     => isAdmin;
  bool get canViewWardFarmers      => isMudhumeni || isAdmin;

  Map<String, dynamic> toMap() => {
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
    'role': role,
    'ward': ward,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
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
        ? DateTime.parse(map['subscribed_at']) : null,
    isPremiumSubscribed: (map['is_premium_subscribed'] ?? 0) == 1,
    premiumExpiresAt: map['premium_expires_at'] != null
        ? DateTime.parse(map['premium_expires_at']) : null,
    securityQuestion: map['security_question'],
    securityAnswerHash: map['security_answer_hash'],
    role: map['role'] as String? ?? 'farmer',
    ward: map['ward'] as String? ?? '',
  );

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
    String? role,
    String? ward,
    FarmProfile? farmProfile,
  }) => UserModel(
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
    role: role ?? this.role,
    ward: ward ?? this.ward,
    farmProfile: farmProfile ?? this.farmProfile,
  );

  @override
  String toString() =>
      'UserModel($userId, $fullName, $roleLabel, $province/$district/$ward)';
}

// ── Role Notification Model ───────────────────────────────
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

  const RoleNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.reason,
    required this.fromRole,
    required this.fromName,
    required this.createdAt,
    this.isRead = false,
  });

  factory RoleNotification.fromMap(Map<String, dynamic> m) =>
      RoleNotification(
        id: m['id'],
        userId: m['user_id'],
        title: m['title'],
        message: m['message'],
        reason: m['reason'] ?? '',
        fromRole: m['from_role'] ?? '',
        fromName: m['from_name'] ?? '',
        createdAt: DateTime.parse(m['created_at']),
        isRead: (m['is_read'] ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
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

// ── Farm Profile Model — unchanged ────────────────────────
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

  Map<String, dynamic> toMap() => {
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

  factory FarmProfile.fromMap(Map<String, dynamic> map) => FarmProfile(
    userId: map['user_id'],
    farmSizeHectares: (map['farm_size_hectares'] as num).toDouble(),
    farmSizeCategory: map['farm_size_category'],
    crops: (map['crops'] as String).split(',').where((c) => c.isNotEmpty).toList(),
    livestock: (map['livestock'] as String).split(',').where((l) => l.isNotEmpty).toList(),
    soilType: map['soil_type'],
    waterSource: map['water_source'],
    hasIrrigation: map['has_irrigation'] == 1,
    updatedAt: DateTime.parse(map['updated_at']),
  );

  static String categoryFromSize(double hectares) {
    if (hectares < 5) return 'small';
    if (hectares <= 50) return 'medium';
    return 'large';
  }
}

// ── Unknown District Model — unchanged ────────────────────
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'district_name': districtName,
    'province_suggested': provinceSuggested,
    'submitted_by_user_id': submittedByUserId,
    'submitted_at': submittedAt.toIso8601String(),
    'status': status,
  };
}