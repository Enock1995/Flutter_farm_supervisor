// lib/models/mudhumeni_model.dart
// Developed by Sir Enocks — Cor Technologies

class MudhumeniProfile {
  final int? id;
  final String userId;
  final String fullName;
  final String employeeId;
  final String ward;
  final String district;
  final String idPhotoPath; // local file path
  final String status; // 'pending' | 'verified' | 'rejected'
  final String createdAt;

  const MudhumeniProfile({
    this.id,
    required this.userId,
    required this.fullName,
    required this.employeeId,
    required this.ward,
    required this.district,
    required this.idPhotoPath,
    required this.status,
    required this.createdAt,
  });

  factory MudhumeniProfile.fromMap(Map<String, dynamic> m) =>
      MudhumeniProfile(
        id: m['id'] as int?,
        userId: m['user_id'] as String? ?? '',
        fullName: m['full_name'] as String? ?? '',
        employeeId: m['employee_id'] as String? ?? '',
        ward: m['ward'] as String? ?? '',
        district: m['district'] as String? ?? '',
        idPhotoPath: m['id_photo_path'] as String? ?? '',
        status: m['status'] as String? ?? 'pending',
        createdAt: m['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'full_name': fullName,
        'employee_id': employeeId,
        'ward': ward,
        'district': district,
        'id_photo_path': idPhotoPath,
        'status': status,
        'created_at': createdAt,
      };
}

class KnowledgePost {
  final int? id;
  final String authorId;
  final String authorName;
  final String ward;
  final String district;
  final String postType; // 'tip'|'pest_alert'|'disease_alert'|'seasonal'|'weather'
  final String title;
  final String body;
  final String photoPath;
  final bool isRead;
  final String createdAt;

  const KnowledgePost({
    this.id,
    required this.authorId,
    required this.authorName,
    required this.ward,
    required this.district,
    required this.postType,
    required this.title,
    required this.body,
    required this.photoPath,
    required this.isRead,
    required this.createdAt,
  });

  factory KnowledgePost.fromMap(Map<String, dynamic> m) => KnowledgePost(
        id: m['id'] as int?,
        authorId: m['author_id'] as String? ?? '',
        authorName: m['author_name'] as String? ?? '',
        ward: m['ward'] as String? ?? '',
        district: m['district'] as String? ?? '',
        postType: m['post_type'] as String? ?? 'tip',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        photoPath: m['photo_path'] as String? ?? '',
        isRead: (m['is_read'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'author_id': authorId,
        'author_name': authorName,
        'ward': ward,
        'district': district,
        'post_type': postType,
        'title': title,
        'body': body,
        'photo_path': photoPath,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt,
      };
}

class QaQuestion {
  final int? id;
  final String authorId;
  final String authorName;
  final String ward;
  final String targetMudhumeniId; // '' = public
  final bool isPublic;
  final String question;
  final String answer; // '' = unanswered
  final String answeredBy;
  final bool answeredByMudhumeni;
  final int upvotes;
  final bool madePublic;
  final String createdAt;
  final String answeredAt;

  const QaQuestion({
    this.id,
    required this.authorId,
    required this.authorName,
    required this.ward,
    required this.targetMudhumeniId,
    required this.isPublic,
    required this.question,
    required this.answer,
    required this.answeredBy,
    required this.answeredByMudhumeni,
    required this.upvotes,
    required this.madePublic,
    required this.createdAt,
    required this.answeredAt,
  });

  factory QaQuestion.fromMap(Map<String, dynamic> m) => QaQuestion(
        id: m['id'] as int?,
        authorId: m['author_id'] as String? ?? '',
        authorName: m['author_name'] as String? ?? '',
        ward: m['ward'] as String? ?? '',
        targetMudhumeniId: m['target_mudhumeni_id'] as String? ?? '',
        isPublic: (m['is_public'] as int? ?? 0) == 1,
        question: m['question'] as String? ?? '',
        answer: m['answer'] as String? ?? '',
        answeredBy: m['answered_by'] as String? ?? '',
        answeredByMudhumeni: (m['answered_by_mudhumeni'] as int? ?? 0) == 1,
        upvotes: m['upvotes'] as int? ?? 0,
        madePublic: (m['made_public'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String? ?? '',
        answeredAt: m['answered_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'author_id': authorId,
        'author_name': authorName,
        'ward': ward,
        'target_mudhumeni_id': targetMudhumeniId,
        'is_public': isPublic ? 1 : 0,
        'question': question,
        'answer': answer,
        'answered_by': answeredBy,
        'answered_by_mudhumeni': answeredByMudhumeni ? 1 : 0,
        'upvotes': upvotes,
        'made_public': madePublic ? 1 : 0,
        'created_at': createdAt,
        'answered_at': answeredAt,
      };
}

class CommunityPost {
  final int? id;
  final String authorId;
  final String authorName;
  final String ward;
  final String postType; // 'text'|'photo'|'poll'
  final String content;
  final String photoPath;
  final String pollOptions; // JSON encoded list
  final int reactions;
  final bool isDeleted;
  final String createdAt;

  const CommunityPost({
    this.id,
    required this.authorId,
    required this.authorName,
    required this.ward,
    required this.postType,
    required this.content,
    required this.photoPath,
    required this.pollOptions,
    required this.reactions,
    required this.isDeleted,
    required this.createdAt,
  });

  factory CommunityPost.fromMap(Map<String, dynamic> m) => CommunityPost(
        id: m['id'] as int?,
        authorId: m['author_id'] as String? ?? '',
        authorName: m['author_name'] as String? ?? '',
        ward: m['ward'] as String? ?? '',
        postType: m['post_type'] as String? ?? 'text',
        content: m['content'] as String? ?? '',
        photoPath: m['photo_path'] as String? ?? '',
        pollOptions: m['poll_options'] as String? ?? '[]',
        reactions: m['reactions'] as int? ?? 0,
        isDeleted: (m['is_deleted'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'author_id': authorId,
        'author_name': authorName,
        'ward': ward,
        'post_type': postType,
        'content': content,
        'photo_path': photoPath,
        'poll_options': pollOptions,
        'reactions': reactions,
        'is_deleted': isDeleted ? 1 : 0,
        'created_at': createdAt,
      };
}

class FieldVisit {
  final int? id;
  final String farmerId;
  final String farmerName;
  final String mudhumeniId;
  final String ward;
  final String issueDescription;
  final String preferredDate;
  final String confirmedDate;
  final String status; // 'requested'|'confirmed'|'rescheduled'|'completed'
  final String visitNotes;
  final String createdAt;

  const FieldVisit({
    this.id,
    required this.farmerId,
    required this.farmerName,
    required this.mudhumeniId,
    required this.ward,
    required this.issueDescription,
    required this.preferredDate,
    required this.confirmedDate,
    required this.status,
    required this.visitNotes,
    required this.createdAt,
  });

  factory FieldVisit.fromMap(Map<String, dynamic> m) => FieldVisit(
        id: m['id'] as int?,
        farmerId: m['farmer_id'] as String? ?? '',
        farmerName: m['farmer_name'] as String? ?? '',
        mudhumeniId: m['mudhumeni_id'] as String? ?? '',
        ward: m['ward'] as String? ?? '',
        issueDescription: m['issue_description'] as String? ?? '',
        preferredDate: m['preferred_date'] as String? ?? '',
        confirmedDate: m['confirmed_date'] as String? ?? '',
        status: m['status'] as String? ?? 'requested',
        visitNotes: m['visit_notes'] as String? ?? '',
        createdAt: m['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'farmer_id': farmerId,
        'farmer_name': farmerName,
        'mudhumeni_id': mudhumeniId,
        'ward': ward,
        'issue_description': issueDescription,
        'preferred_date': preferredDate,
        'confirmed_date': confirmedDate,
        'status': status,
        'visit_notes': visitNotes,
        'created_at': createdAt,
      };
}

class SeasonalEntry {
  final int? id;
  final String mudhumeniId;
  final String ward;
  final String cropType;
  final String activityType; // 'plant'|'fertilize'|'spray'|'harvest'
  final String scheduledDate;
  final String notes;
  final bool isDone;
  final String season; // e.g. '2025/2026'
  final String createdAt;

  const SeasonalEntry({
    this.id,
    required this.mudhumeniId,
    required this.ward,
    required this.cropType,
    required this.activityType,
    required this.scheduledDate,
    required this.notes,
    required this.isDone,
    required this.season,
    required this.createdAt,
  });

  factory SeasonalEntry.fromMap(Map<String, dynamic> m) => SeasonalEntry(
        id: m['id'] as int?,
        mudhumeniId: m['mudhumeni_id'] as String? ?? '',
        ward: m['ward'] as String? ?? '',
        cropType: m['crop_type'] as String? ?? '',
        activityType: m['activity_type'] as String? ?? 'plant',
        scheduledDate: m['scheduled_date'] as String? ?? '',
        notes: m['notes'] as String? ?? '',
        isDone: (m['is_done'] as int? ?? 0) == 1,
        season: m['season'] as String? ?? '',
        createdAt: m['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'mudhumeni_id': mudhumeniId,
        'ward': ward,
        'crop_type': cropType,
        'activity_type': activityType,
        'scheduled_date': scheduledDate,
        'notes': notes,
        'is_done': isDone ? 1 : 0,
        'season': season,
        'created_at': createdAt,
      };
}

class ProblemReport {
  final int? id;
  final String reporterId;
  final String reporterName;
  final String ward;
  final String district;
  final String problemType; // 'pest'|'disease'|'weather'|'other'
  final String description;
  final String cropAffected;
  final double latitude;
  final double longitude;
  final bool isResolved;
  final String createdAt;

  const ProblemReport({
    this.id,
    required this.reporterId,
    required this.reporterName,
    required this.ward,
    required this.district,
    required this.problemType,
    required this.description,
    required this.cropAffected,
    required this.latitude,
    required this.longitude,
    required this.isResolved,
    required this.createdAt,
  });

  factory ProblemReport.fromMap(Map<String, dynamic> m) => ProblemReport(
        id: m['id'] as int?,
        reporterId: m['reporter_id'] as String? ?? '',
        reporterName: m['reporter_name'] as String? ?? '',
        ward: m['ward'] as String? ?? '',
        district: m['district'] as String? ?? '',
        problemType: m['problem_type'] as String? ?? 'pest',
        description: m['description'] as String? ?? '',
        cropAffected: m['crop_affected'] as String? ?? '',
        latitude: (m['latitude'] as num? ?? 0.0).toDouble(),
        longitude: (m['longitude'] as num? ?? 0.0).toDouble(),
        isResolved: (m['is_resolved'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'reporter_id': reporterId,
        'reporter_name': reporterName,
        'ward': ward,
        'district': district,
        'problem_type': problemType,
        'description': description,
        'crop_affected': cropAffected,
        'latitude': latitude,
        'longitude': longitude,
        'is_resolved': isResolved ? 1 : 0,
        'created_at': createdAt,
      };
}