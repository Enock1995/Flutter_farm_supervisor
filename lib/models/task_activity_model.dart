// lib/models/task_activity_model.dart
// Developed by Sir Enocks — Cor Technologies

// ── TASK PRIORITY ─────────────────────────────────────────
enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:    return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high:   return 'High';
      case TaskPriority.urgent: return 'Urgent';
    }
  }

  String get emoji {
    switch (this) {
      case TaskPriority.low:    return '🟢';
      case TaskPriority.medium: return '🟡';
      case TaskPriority.high:   return '🟠';
      case TaskPriority.urgent: return '🔴';
    }
  }
}

// ── TASK STATUS ───────────────────────────────────────────
enum TaskStatus { pending, inProgress, completed, cancelled }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:    return 'Pending';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.completed:  return 'Completed';
      case TaskStatus.cancelled:  return 'Cancelled';
    }
  }
}

// ── TASK MODEL ────────────────────────────────────────────
class TaskModel {
  final String id;
  final String farmId;
  final String ownerId;

  // Assignment
  final String? assignedWorkerId;
  final String? assignedWorkerName;

  // Content
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;

  // Scheduling
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Location context
  final String? fieldOrPlot;

  // Completion note (worker fills in on completion)
  final String? completionNote;

  const TaskModel({
    required this.id,
    required this.farmId,
    required this.ownerId,
    this.assignedWorkerId,
    this.assignedWorkerName,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.fieldOrPlot,
    this.completionNote,
  });

  bool get isOverdue =>
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled &&
      DateTime.now().isAfter(dueDate);

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'farm_id': farmId,
        'owner_id': ownerId,
        'assigned_worker_id': assignedWorkerId,
        'assigned_worker_name': assignedWorkerName,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': status.name,
        'due_date': dueDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'field_or_plot': fieldOrPlot,
        'completion_note': completionNote,
      };

  factory TaskModel.fromMap(Map<String, dynamic> m) => TaskModel(
        id: m['id'],
        farmId: m['farm_id'],
        ownerId: m['owner_id'],
        assignedWorkerId: m['assigned_worker_id'],
        assignedWorkerName: m['assigned_worker_name'],
        title: m['title'],
        description: m['description'],
        priority: TaskPriority.values
            .firstWhere((e) => e.name == m['priority'],
                orElse: () => TaskPriority.medium),
        status: TaskStatus.values
            .firstWhere((e) => e.name == m['status'],
                orElse: () => TaskStatus.pending),
        dueDate: DateTime.parse(m['due_date']),
        createdAt: DateTime.parse(m['created_at']),
        startedAt:
            m['started_at'] != null ? DateTime.parse(m['started_at']) : null,
        completedAt: m['completed_at'] != null
            ? DateTime.parse(m['completed_at'])
            : null,
        fieldOrPlot: m['field_or_plot'],
        completionNote: m['completion_note'],
      );

  TaskModel copyWith({
    String? assignedWorkerId,
    String? assignedWorkerName,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? startedAt,
    DateTime? completedAt,
    String? fieldOrPlot,
    String? completionNote,
  }) =>
      TaskModel(
        id: id,
        farmId: farmId,
        ownerId: ownerId,
        assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
        assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
        title: title ?? this.title,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        fieldOrPlot: fieldOrPlot ?? this.fieldOrPlot,
        completionNote: completionNote ?? this.completionNote,
      );
}

// ── ACTIVITY TYPE ─────────────────────────────────────────
enum ActivityType {
  taskCreated,
  taskStarted,
  taskCompleted,
  taskCancelled,
  workerClockedIn,
  workerClockedOut,
  workerJoined,
  workerApproved,
  farmRegistered,
}

extension ActivityTypeX on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.taskCreated:    return 'Task Created';
      case ActivityType.taskStarted:    return 'Task Started';
      case ActivityType.taskCompleted:  return 'Task Completed';
      case ActivityType.taskCancelled:  return 'Task Cancelled';
      case ActivityType.workerClockedIn:  return 'Clocked In';
      case ActivityType.workerClockedOut: return 'Clocked Out';
      case ActivityType.workerJoined:   return 'Worker Joined';
      case ActivityType.workerApproved: return 'Worker Approved';
      case ActivityType.farmRegistered: return 'Farm Registered';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.taskCreated:    return '📋';
      case ActivityType.taskStarted:    return '▶️';
      case ActivityType.taskCompleted:  return '✅';
      case ActivityType.taskCancelled:  return '❌';
      case ActivityType.workerClockedIn:  return '🟢';
      case ActivityType.workerClockedOut: return '🔴';
      case ActivityType.workerJoined:   return '👤';
      case ActivityType.workerApproved: return '✔️';
      case ActivityType.farmRegistered: return '🌾';
    }
  }
}

// ── ACTIVITY FEED ITEM ────────────────────────────────────
class ActivityItem {
  final String id;
  final String farmId;
  final String ownerId;
  final ActivityType type;
  final String actorName;   // who triggered it
  final String title;       // short headline
  final String? detail;     // optional extra detail
  final String? referenceId; // task id / worker id / etc
  final DateTime createdAt;

  const ActivityItem({
    required this.id,
    required this.farmId,
    required this.ownerId,
    required this.type,
    required this.actorName,
    required this.title,
    this.detail,
    this.referenceId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'farm_id': farmId,
        'owner_id': ownerId,
        'type': type.name,
        'actor_name': actorName,
        'title': title,
        'detail': detail,
        'reference_id': referenceId,
        'created_at': createdAt.toIso8601String(),
      };

  factory ActivityItem.fromMap(Map<String, dynamic> m) => ActivityItem(
        id: m['id'],
        farmId: m['farm_id'],
        ownerId: m['owner_id'],
        type: ActivityType.values
            .firstWhere((e) => e.name == m['type'],
                orElse: () => ActivityType.taskCreated),
        actorName: m['actor_name'],
        title: m['title'],
        detail: m['detail'],
        referenceId: m['reference_id'],
        createdAt: DateTime.parse(m['created_at']),
      );
}