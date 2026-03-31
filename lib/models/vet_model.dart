// lib/models/vet_model.dart
// Developed by Sir Enocks Cor Technologies
// Veterinary Services Module - All model classes

import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ══════════════════════════════════════════════════════════════════════════════

enum VetStatus {
  pending,
  verified,
  suspended;

  String get label {
    switch (this) {
      case VetStatus.pending:
        return 'Pending Approval';
      case VetStatus.verified:
        return 'Verified';
      case VetStatus.suspended:
        return 'Suspended';
    }
  }

  String get emoji {
    switch (this) {
      case VetStatus.pending:
        return '⏳';
      case VetStatus.verified:
        return '✅';
      case VetStatus.suspended:
        return '⛔';
    }
  }
}

enum VetSpecialization {
  general,
  poultry,
  dairy,
  beef,
  smallAnimals;

  String get label {
    switch (this) {
      case VetSpecialization.general:
        return 'General Veterinary';
      case VetSpecialization.poultry:
        return 'Poultry Specialist';
      case VetSpecialization.dairy:
        return 'Dairy Cattle Specialist';
      case VetSpecialization.beef:
        return 'Beef Cattle Specialist';
      case VetSpecialization.smallAnimals:
        return 'Small Animals';
    }
  }
}

enum AnimalType {
  cattle,
  goats,
  chickens,
  pigs,
  sheep,
  rabbits,
  all;

  String get label {
    switch (this) {
      case AnimalType.cattle:
        return 'Cattle';
      case AnimalType.goats:
        return 'Goats';
      case AnimalType.chickens:
        return 'Chickens';
      case AnimalType.pigs:
        return 'Pigs';
      case AnimalType.sheep:
        return 'Sheep';
      case AnimalType.rabbits:
        return 'Rabbits';
      case AnimalType.all:
        return 'All Animals';
    }
  }

  String get emoji {
    switch (this) {
      case AnimalType.cattle:
        return '🐄';
      case AnimalType.goats:
        return '🐐';
      case AnimalType.chickens:
        return '🐔';
      case AnimalType.pigs:
        return '🐷';
      case AnimalType.sheep:
        return '🐑';
      case AnimalType.rabbits:
        return '🐰';
      case AnimalType.all:
        return '🐾';
    }
  }
}

enum PostType {
  article,
  alert,
  tip,
  diseaseWarning;

  String get label {
    switch (this) {
      case PostType.article:
        return 'Article';
      case PostType.alert:
        return 'Alert';
      case PostType.tip:
        return 'Quick Tip';
      case PostType.diseaseWarning:
        return 'Disease Warning';
    }
  }

  String get emoji {
    switch (this) {
      case PostType.article:
        return '📄';
      case PostType.alert:
        return '⚠️';
      case PostType.tip:
        return '💡';
      case PostType.diseaseWarning:
        return '🦠';
    }
  }
}

enum VisitStatus {
  requested,
  confirmed,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case VisitStatus.requested:
        return 'Requested';
      case VisitStatus.confirmed:
        return 'Confirmed';
      case VisitStatus.completed:
        return 'Completed';
      case VisitStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case VisitStatus.requested:
        return '📋';
      case VisitStatus.confirmed:
        return '✅';
      case VisitStatus.completed:
        return '🎯';
      case VisitStatus.cancelled:
        return '❌';
    }
  }
}

enum QuestionUrgency {
  urgent,
  normal,
  routine;

  String get label {
    switch (this) {
      case QuestionUrgency.urgent:
        return 'Urgent';
      case QuestionUrgency.normal:
        return 'Normal';
      case QuestionUrgency.routine:
        return 'Routine';
    }
  }

  String get emoji {
    switch (this) {
      case QuestionUrgency.urgent:
        return '🚨';
      case QuestionUrgency.normal:
        return '📌';
      case QuestionUrgency.routine:
        return '📝';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VET PROFILE
// ══════════════════════════════════════════════════════════════════════════════

@immutable
class VetProfile {
  final int? id;
  final String userId;
  final String fullName;
  final String registrationNumber;
  final String specialization;
  final String qualification;
  final int yearsExperience;
  final String district;
  final String wards; // Comma-separated
  final String province;
  final String phone;
  final String email;
  final String idPhotoPath;
  final String certificatePhotoPath;
  final String status;
  final String createdAt;

  const VetProfile({
    this.id,
    required this.userId,
    required this.fullName,
    required this.registrationNumber,
    this.specialization = 'general',
    required this.qualification,
    this.yearsExperience = 0,
    required this.district,
    this.wards = '',
    required this.province,
    required this.phone,
    this.email = '',
    this.idPhotoPath = '',
    this.certificatePhotoPath = '',
    this.status = 'pending',
    required this.createdAt,
  });

  VetStatus get statusEnum {
    switch (status.toLowerCase()) {
      case 'verified':
        return VetStatus.verified;
      case 'suspended':
        return VetStatus.suspended;
      default:
        return VetStatus.pending;
    }
  }

  VetSpecialization get specializationEnum {
    switch (specialization.toLowerCase()) {
      case 'poultry':
        return VetSpecialization.poultry;
      case 'dairy':
        return VetSpecialization.dairy;
      case 'beef':
        return VetSpecialization.beef;
      case 'small_animals':
      case 'smallanimals':
        return VetSpecialization.smallAnimals;
      default:
        return VetSpecialization.general;
    }
  }

  List<String> get wardsList =>
      wards.isEmpty ? [] : wards.split(',').map((w) => w.trim()).toList();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'full_name': fullName,
      'registration_number': registrationNumber,
      'specialization': specialization,
      'qualification': qualification,
      'years_experience': yearsExperience,
      'district': district,
      'wards': wards,
      'province': province,
      'phone': phone,
      'email': email,
      'id_photo_path': idPhotoPath,
      'certificate_photo_path': certificatePhotoPath,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory VetProfile.fromMap(Map<String, dynamic> map) {
    return VetProfile(
      id: map['id'] as int?,
      userId: map['user_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      registrationNumber: map['registration_number'] as String? ?? '',
      specialization: map['specialization'] as String? ?? 'general',
      qualification: map['qualification'] as String? ?? '',
      yearsExperience: map['years_experience'] as int? ?? 0,
      district: map['district'] as String? ?? '',
      wards: map['wards'] as String? ?? '',
      province: map['province'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      idPhotoPath: map['id_photo_path'] as String? ?? '',
      certificatePhotoPath: map['certificate_photo_path'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  VetProfile copyWith({
    int? id,
    String? userId,
    String? fullName,
    String? registrationNumber,
    String? specialization,
    String? qualification,
    int? yearsExperience,
    String? district,
    String? wards,
    String? province,
    String? phone,
    String? email,
    String? idPhotoPath,
    String? certificatePhotoPath,
    String? status,
    String? createdAt,
  }) {
    return VetProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      district: district ?? this.district,
      wards: wards ?? this.wards,
      province: province ?? this.province,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      idPhotoPath: idPhotoPath ?? this.idPhotoPath,
      certificatePhotoPath: certificatePhotoPath ?? this.certificatePhotoPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VET KNOWLEDGE POST
// ══════════════════════════════════════════════════════════════════════════════

@immutable
class VetKnowledgePost {
  final int? id;
  final String authorId;
  final String authorName;
  final int vetId;
  final String district;
  final String wards;
  final String postType;
  final String category;
  final String animalType;
  final String title;
  final String body;
  final String photoPath;
  final int isUrgent;
  final int views;
  final int isRead;
  final String createdAt;

  const VetKnowledgePost({
    this.id,
    required this.authorId,
    required this.authorName,
    required this.vetId,
    required this.district,
    this.wards = '',
    this.postType = 'article',
    this.category = 'general',
    this.animalType = 'all',
    required this.title,
    required this.body,
    this.photoPath = '',
    this.isUrgent = 0,
    this.views = 0,
    this.isRead = 0,
    required this.createdAt,
  });

  PostType get postTypeEnum {
    switch (postType.toLowerCase()) {
      case 'alert':
        return PostType.alert;
      case 'tip':
        return PostType.tip;
      case 'disease_warning':
      case 'diseasewarning':
        return PostType.diseaseWarning;
      default:
        return PostType.article;
    }
  }

  AnimalType get animalTypeEnum {
    switch (animalType.toLowerCase()) {
      case 'cattle':
        return AnimalType.cattle;
      case 'goats':
        return AnimalType.goats;
      case 'chickens':
        return AnimalType.chickens;
      case 'pigs':
        return AnimalType.pigs;
      case 'sheep':
        return AnimalType.sheep;
      case 'rabbits':
        return AnimalType.rabbits;
      default:
        return AnimalType.all;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'vet_id': vetId,
      'district': district,
      'wards': wards,
      'post_type': postType,
      'category': category,
      'animal_type': animalType,
      'title': title,
      'body': body,
      'photo_path': photoPath,
      'is_urgent': isUrgent,
      'views': views,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }

  factory VetKnowledgePost.fromMap(Map<String, dynamic> map) {
    return VetKnowledgePost(
      id: map['id'] as int?,
      authorId: map['author_id'] as String? ?? '',
      authorName: map['author_name'] as String? ?? '',
      vetId: map['vet_id'] as int? ?? 0,
      district: map['district'] as String? ?? '',
      wards: map['wards'] as String? ?? '',
      postType: map['post_type'] as String? ?? 'article',
      category: map['category'] as String? ?? 'general',
      animalType: map['animal_type'] as String? ?? 'all',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      photoPath: map['photo_path'] as String? ?? '',
      isUrgent: map['is_urgent'] as int? ?? 0,
      views: map['views'] as int? ?? 0,
      isRead: map['is_read'] as int? ?? 0,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VET Q&A QUESTION
// ══════════════════════════════════════════════════════════════════════════════

@immutable
class VetQuestion {
  final int? id;
  final String authorId;
  final String authorName;
  final String animalType;
  final int animalCount;
  final String district;
  final String ward;
  final String targetVetId;
  final int isPublic;
  final String question;
  final String symptoms;
  final String duration;
  final String photoPath;
  final String answer;
  final String answeredBy;
  final int answeredByVet;
  final String diagnosis;
  final String treatmentPlan;
  final int upvotes;
  final String upvotedBy;
  final int madePublic;
  final String urgency;
  final String createdAt;
  final String answeredAt;

  const VetQuestion({
    this.id,
    required this.authorId,
    required this.authorName,
    required this.animalType,
    this.animalCount = 1,
    required this.district,
    required this.ward,
    this.targetVetId = '',
    this.isPublic = 0,
    required this.question,
    this.symptoms = '',
    this.duration = '',
    this.photoPath = '',
    this.answer = '',
    this.answeredBy = '',
    this.answeredByVet = 0,
    this.diagnosis = '',
    this.treatmentPlan = '',
    this.upvotes = 0,
    this.upvotedBy = '',
    this.madePublic = 0,
    this.urgency = 'normal',
    required this.createdAt,
    this.answeredAt = '',
  });

  AnimalType get animalTypeEnum {
    switch (animalType.toLowerCase()) {
      case 'cattle':
        return AnimalType.cattle;
      case 'goats':
        return AnimalType.goats;
      case 'chickens':
        return AnimalType.chickens;
      case 'pigs':
        return AnimalType.pigs;
      case 'sheep':
        return AnimalType.sheep;
      case 'rabbits':
        return AnimalType.rabbits;
      default:
        return AnimalType.all;
    }
  }

  QuestionUrgency get urgencyEnum {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return QuestionUrgency.urgent;
      case 'routine':
        return QuestionUrgency.routine;
      default:
        return QuestionUrgency.normal;
    }
  }

  bool get isAnswered => answer.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'animal_type': animalType,
      'animal_count': animalCount,
      'district': district,
      'ward': ward,
      'target_vet_id': targetVetId,
      'is_public': isPublic,
      'question': question,
      'symptoms': symptoms,
      'duration': duration,
      'photo_path': photoPath,
      'answer': answer,
      'answered_by': answeredBy,
      'answered_by_vet': answeredByVet,
      'diagnosis': diagnosis,
      'treatment_plan': treatmentPlan,
      'upvotes': upvotes,
      'upvoted_by': upvotedBy,
      'made_public': madePublic,
      'urgency': urgency,
      'created_at': createdAt,
      'answered_at': answeredAt,
    };
  }

  factory VetQuestion.fromMap(Map<String, dynamic> map) {
    return VetQuestion(
      id: map['id'] as int?,
      authorId: map['author_id'] as String? ?? '',
      authorName: map['author_name'] as String? ?? '',
      animalType: map['animal_type'] as String? ?? 'cattle',
      animalCount: map['animal_count'] as int? ?? 1,
      district: map['district'] as String? ?? '',
      ward: map['ward'] as String? ?? '',
      targetVetId: map['target_vet_id'] as String? ?? '',
      isPublic: map['is_public'] as int? ?? 0,
      question: map['question'] as String? ?? '',
      symptoms: map['symptoms'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      photoPath: map['photo_path'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
      answeredBy: map['answered_by'] as String? ?? '',
      answeredByVet: map['answered_by_vet'] as int? ?? 0,
      diagnosis: map['diagnosis'] as String? ?? '',
      treatmentPlan: map['treatment_plan'] as String? ?? '',
      upvotes: map['upvotes'] as int? ?? 0,
      upvotedBy: map['upvoted_by'] as String? ?? '',
      madePublic: map['made_public'] as int? ?? 0,
      urgency: map['urgency'] as String? ?? 'normal',
      createdAt: map['created_at'] as String? ?? '',
      answeredAt: map['answered_at'] as String? ?? '',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VET FARM VISIT
// ══════════════════════════════════════════════════════════════════════════════

@immutable
class VetVisit {
  final int? id;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String vetId;
  final String vetName;
  final String district;
  final String ward;
  final String animalType;
  final String issueDescription;
  final int animalCount;
  final String preferredDate;
  final String confirmedDate;
  final String visitTime;
  final String status;
  final String visitNotes;
  final String diagnosis;
  final String treatmentGiven;
  final int followUpNeeded;
  final String followUpDate;
  final double visitFeeUsd;
  final int isPaid;
  final double latitude;
  final double longitude;
  final String createdAt;
  final String completedAt;

  const VetVisit({
    this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    required this.vetId,
    required this.vetName,
    required this.district,
    required this.ward,
    required this.animalType,
    required this.issueDescription,
    this.animalCount = 1,
    required this.preferredDate,
    this.confirmedDate = '',
    this.visitTime = '',
    this.status = 'requested',
    this.visitNotes = '',
    this.diagnosis = '',
    this.treatmentGiven = '',
    this.followUpNeeded = 0,
    this.followUpDate = '',
    this.visitFeeUsd = 0.0,
    this.isPaid = 0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.createdAt,
    this.completedAt = '',
  });

  VisitStatus get statusEnum {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return VisitStatus.confirmed;
      case 'completed':
        return VisitStatus.completed;
      case 'cancelled':
        return VisitStatus.cancelled;
      default:
        return VisitStatus.requested;
    }
  }

  AnimalType get animalTypeEnum {
    switch (animalType.toLowerCase()) {
      case 'cattle':
        return AnimalType.cattle;
      case 'goats':
        return AnimalType.goats;
      case 'chickens':
        return AnimalType.chickens;
      case 'pigs':
        return AnimalType.pigs;
      case 'sheep':
        return AnimalType.sheep;
      case 'rabbits':
        return AnimalType.rabbits;
      default:
        return AnimalType.all;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'farmer_phone': farmerPhone,
      'vet_id': vetId,
      'vet_name': vetName,
      'district': district,
      'ward': ward,
      'animal_type': animalType,
      'issue_description': issueDescription,
      'animal_count': animalCount,
      'preferred_date': preferredDate,
      'confirmed_date': confirmedDate,
      'visit_time': visitTime,
      'status': status,
      'visit_notes': visitNotes,
      'diagnosis': diagnosis,
      'treatment_given': treatmentGiven,
      'follow_up_needed': followUpNeeded,
      'follow_up_date': followUpDate,
      'visit_fee_usd': visitFeeUsd,
      'is_paid': isPaid,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }

  factory VetVisit.fromMap(Map<String, dynamic> map) {
    return VetVisit(
      id: map['id'] as int?,
      farmerId: map['farmer_id'] as String? ?? '',
      farmerName: map['farmer_name'] as String? ?? '',
      farmerPhone: map['farmer_phone'] as String? ?? '',
      vetId: map['vet_id'] as String? ?? '',
      vetName: map['vet_name'] as String? ?? '',
      district: map['district'] as String? ?? '',
      ward: map['ward'] as String? ?? '',
      animalType: map['animal_type'] as String? ?? 'cattle',
      issueDescription: map['issue_description'] as String? ?? '',
      animalCount: map['animal_count'] as int? ?? 1,
      preferredDate: map['preferred_date'] as String? ?? '',
      confirmedDate: map['confirmed_date'] as String? ?? '',
      visitTime: map['visit_time'] as String? ?? '',
      status: map['status'] as String? ?? 'requested',
      visitNotes: map['visit_notes'] as String? ?? '',
      diagnosis: map['diagnosis'] as String? ?? '',
      treatmentGiven: map['treatment_given'] as String? ?? '',
      followUpNeeded: map['follow_up_needed'] as int? ?? 0,
      followUpDate: map['follow_up_date'] as String? ?? '',
      visitFeeUsd: (map['visit_fee_usd'] as num?)?.toDouble() ?? 0.0,
      isPaid: map['is_paid'] as int? ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] as String? ?? '',
      completedAt: map['completed_at'] as String? ?? '',
    );
  }

  VetVisit copyWith({
    int? id,
    String? status,
    String? confirmedDate,
    String? visitTime,
    String? visitNotes,
    String? diagnosis,
    String? treatmentGiven,
    int? followUpNeeded,
    String? followUpDate,
    double? visitFeeUsd,
    int? isPaid,
    String? completedAt,
  }) {
    return VetVisit(
      id: id ?? this.id,
      farmerId: farmerId,
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      vetId: vetId,
      vetName: vetName,
      district: district,
      ward: ward,
      animalType: animalType,
      issueDescription: issueDescription,
      animalCount: animalCount,
      preferredDate: preferredDate,
      confirmedDate: confirmedDate ?? this.confirmedDate,
      visitTime: visitTime ?? this.visitTime,
      status: status ?? this.status,
      visitNotes: visitNotes ?? this.visitNotes,
      diagnosis: diagnosis ?? this.diagnosis,
      treatmentGiven: treatmentGiven ?? this.treatmentGiven,
      followUpNeeded: followUpNeeded ?? this.followUpNeeded,
      followUpDate: followUpDate ?? this.followUpDate,
      visitFeeUsd: visitFeeUsd ?? this.visitFeeUsd,
      isPaid: isPaid ?? this.isPaid,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VET DISEASE REPORT
// ══════════════════════════════════════════════════════════════════════════════

@immutable
class VetDiseaseReport {
  final int? id;
  final String reporterId;
  final String reporterName;
  final String reporterType;
  final String district;
  final String ward;
  final String diseaseName;
  final String animalType;
  final int affectedCount;
  final int deaths;
  final String symptoms;
  final String outbreakLevel;
  final double latitude;
  final double longitude;
  final String photoPath;
  final int isVerified;
  final String verifiedBy;
  final String verifiedAt;
  final int isResolved;
  final String resolvedAt;
  final String actionTaken;
  final String createdAt;

  const VetDiseaseReport({
    this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterType,
    required this.district,
    required this.ward,
    required this.diseaseName,
    required this.animalType,
    this.affectedCount = 1,
    this.deaths = 0,
    required this.symptoms,
    this.outbreakLevel = 'isolated',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.photoPath = '',
    this.isVerified = 0,
    this.verifiedBy = '',
    this.verifiedAt = '',
    this.isResolved = 0,
    this.resolvedAt = '',
    this.actionTaken = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reporter_type': reporterType,
      'district': district,
      'ward': ward,
      'disease_name': diseaseName,
      'animal_type': animalType,
      'affected_count': affectedCount,
      'deaths': deaths,
      'symptoms': symptoms,
      'outbreak_level': outbreakLevel,
      'latitude': latitude,
      'longitude': longitude,
      'photo_path': photoPath,
      'is_verified': isVerified,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt,
      'is_resolved': isResolved,
      'resolved_at': resolvedAt,
      'action_taken': actionTaken,
      'created_at': createdAt,
    };
  }

  factory VetDiseaseReport.fromMap(Map<String, dynamic> map) {
    return VetDiseaseReport(
      id: map['id'] as int?,
      reporterId: map['reporter_id'] as String? ?? '',
      reporterName: map['reporter_name'] as String? ?? '',
      reporterType: map['reporter_type'] as String? ?? 'farmer',
      district: map['district'] as String? ?? '',
      ward: map['ward'] as String? ?? '',
      diseaseName: map['disease_name'] as String? ?? '',
      animalType: map['animal_type'] as String? ?? 'cattle',
      affectedCount: map['affected_count'] as int? ?? 1,
      deaths: map['deaths'] as int? ?? 0,
      symptoms: map['symptoms'] as String? ?? '',
      outbreakLevel: map['outbreak_level'] as String? ?? 'isolated',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      photoPath: map['photo_path'] as String? ?? '',
      isVerified: map['is_verified'] as int? ?? 0,
      verifiedBy: map['verified_by'] as String? ?? '',
      verifiedAt: map['verified_at'] as String? ?? '',
      isResolved: map['is_resolved'] as int? ?? 0,
      resolvedAt: map['resolved_at'] as String? ?? '',
      actionTaken: map['action_taken'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}